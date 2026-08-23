import bpy

LIGHTMAP_UV_NAME = "lightmap"
# Look for the last generated bake target name from the previous step
# (Usually 'Lightmap_Bake_Target' or 'Lightmap_Bake_Target_1')
BAKE_NODE_NAME = "Automated_Lightmap_Tex" 

def combine_lightmap_with_diffuse():
    obj = bpy.context.active_object
    if not obj or obj.type != 'MESH' or not obj.data.materials:
        print("Error: Please select a valid mesh object with assigned materials.")
        return

    # Find the primary UV map name (usually the first one in the list)
    primary_uv_name = obj.data.uv_layers[0].name
    if primary_uv_name == LIGHTMAP_UV_NAME and len(obj.data.uv_layers) > 1:
        primary_uv_name = obj.data.uv_layers[1].name

    for mat in obj.data.materials:
        if not mat or not mat.use_nodes:
            continue
            
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        # 1. Locate the core nodes needed
        principled_node = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
        lightmap_tex_node = next((n for n in nodes if n.name.startswith(BAKE_NODE_NAME)), None)
        
        if not principled_node:
            print(f"Skipping material '{mat.name}': No Principled BSDF node found.")
            continue
            
        if not lightmap_tex_node:
            print(f"Skipping material '{mat.name}': Could not find the automated lightmap texture node.")
            continue

        # Find whatever was originally plugged into the Base Color socket
        base_color_input = principled_node.inputs['Base Color']
        original_color_link = next((l for l in links if l.to_socket == base_color_input), None)
        
        # 2. Create the Multiply (Mix Color) Node
        mix_node = nodes.new(type='ShaderNodeMix')
        mix_node.data_type = 'RGBA'
        mix_node.blend_type = 'MULTIPLY'
        mix_node.inputs['Factor'].default_value = 1.0
        mix_node.location = (principled_node.location.x - 250, principled_node.location.y - 100)
        
        # 3. Create Primary UV Map Node for the original texture
        primary_uv_node = nodes.new(type='ShaderNodeUVMap')
        primary_uv_node.uv_map = primary_uv_name
        primary_uv_node.location = (lightmap_tex_node.location.x - 400, lightmap_tex_node.location.y - 300)

        # 4. Wire everything together safely
        if original_color_link:
            original_output_socket = original_color_link.from_socket
            original_tex_node = original_color_link.from_node
            
            # Connect original texture to primary UV map coordinates
            links.new(primary_uv_node.outputs['UV'], original_tex_node.inputs['Vector'])
            
            # Remove old link to Principled BSDF and route through Multiply node
            links.remove(original_color_link)
            links.new(original_output_socket, mix_node.inputs['A'])
        else:
            # If there was no texture, feed the default material color into slot A
            mix_node.inputs['A'].default_value = base_color_input.default_value
            
        # Connect Baked Lightmap into Slot B of Multiply
        links.new(lightmap_tex_node.outputs['Color'], mix_node.inputs['B'])
        
        # Connect the final multiplied result back into the Principled BSDF Base Color
        links.new(mix_node.outputs['Result'], base_color_input)

    print(f"Successfully combined textures for '{obj.name}'. Switch to Material Preview or Rendered view!")

combine_lightmap_with_diffuse()