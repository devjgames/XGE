import bpy

# Set your desired lightmap configuration
LIGHTMAP_NAME = "lightmap"
TEXTURE_NAME = "Lightmap_Bake_Target"
RESOLUTION = 1024  # Options: 1024, 2048, 4096

def setup_lightmap_automation():
    # 1. Validation & Mode Reset
    if bpy.context.active_object and bpy.context.active_object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')

    obj = bpy.context.active_object
    if not obj or obj.type != 'MESH':
        print("Error: Please select a valid mesh object in the 3D Viewport.")
        return
    
    # 2. Manage UV Maps Safely
    uv_maps = obj.data.uv_layers
    if LIGHTMAP_NAME not in uv_maps:
        lightmap_uv = uv_maps.new(name=LIGHTMAP_NAME)
    else:
        lightmap_uv = uv_maps[LIGHTMAP_NAME]
    uv_maps.active = lightmap_uv
    
    # 3. Smart UV Unwrap (Context-Safe alternative to Light Map Pack)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    
    # Uses standard Smart Project with an island margin to prevent bleed
    bpy.ops.uv.smart_project(island_margin=0.02)
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # 4. Handle Bake Target Image Dynamically 
    # If it exists, append a unique ID to avoid data/write lockouts entirely
    base_name = TEXTURE_NAME
    counter = 1
    final_name = base_name
    while final_name in bpy.data.images:
        final_name = f"{base_name}_{counter}"
        counter += 1
        
    bake_image = bpy.data.images.new(
        name=final_name, 
        width=RESOLUTION, 
        height=RESOLUTION, 
        alpha=True, 
        float_buffer=True
    )

    # 5. Inject Material Nodes Cleanly
    if not obj.data.materials:
        mat = bpy.data.materials.new(name="Default_Material")
        mat.use_nodes = True
        obj.data.materials.append(mat)

    for mat in obj.data.materials:
        if not mat or not mat.use_nodes:
            continue
            
        nodes = mat.node_tree.nodes
        for node in nodes:
            node.select = False
            
        # Target distinct names every single run
        tex_node = nodes.new(type='ShaderNodeTexImage')
        tex_node.image = bake_image
        tex_node.location = (-400, 300)
        
        # Force active flag for Cycles Bake target detection
        nodes.active = tex_node
        tex_node.select = True
        
        uv_node = nodes.new(type='ShaderNodeUVMap')
        uv_node.uv_map = LIGHTMAP_NAME
        uv_node.location = (-600, 300)
        
        mat.node_tree.links.new(uv_node.outputs['UV'], tex_node.inputs['Vector'])

    print(f"Successfully configured '{obj.name}' using image: {final_name}")

# Run the completely safe script
setup_lightmap_automation()
