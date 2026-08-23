import bpy

# Create or clear an internal text block for the output
text_block_name = "Mesh_Data_Output"
if text_block_name in bpy.data.texts:
    txt_block = bpy.data.texts[text_block_name]
    txt_block.clear()
else:
    txt_block = bpy.data.texts.new(text_block_name)

def log_print(message):
    """Writes data line by line directly into the Blender Text block."""
    txt_block.write(str(message) + "\n")

# Process active mesh
obj = bpy.context.active_object
if obj and obj.type == 'MESH':
    # Get the evaluated mesh data to ensure accurate indices and data stability
    mesh = obj.data
    uv_layers = mesh.uv_layers
    
    
    # Safely reference the collection layer instances
    uv1_layer = uv_layers[0] if len(uv_layers) > 0 else None
    uv2_layer = uv_layers[1] if len(uv_layers) > 1 else None

    # Helper function to find image from a material's node tree
    def get_material_image(mat):
        if mat and mat.use_nodes and mat.node_tree:
            for node in mat.node_tree.nodes:
                if node.type == 'TEX_IMAGE' and node.image:
                    return node.image.name
        return "No Image"

    for poly in mesh.polygons:
        mat_name = "No Material"
        img_name = "NoImage"
        if poly.material_index < len(obj.material_slots):
            slot = obj.material_slots[poly.material_index]
            if slot.material:
                mat_name = slot.material.name
                img_name = get_material_image(slot.material)
        
        log_print(f"polygon {img_name}")
        
        for loop_idx in poly.loop_indices:
            loop = mesh.loops[loop_idx]
            vert_idx = loop.vertex_index
            co = mesh.vertices[vert_idx].co
            
            # Access the individual UV value coordinates safely using data array index bounds
            uv_val1 = uv1_layer.data[loop_idx].uv if uv1_layer else (0.0, 0.0)
            uv_val2 = uv2_layer.data[loop_idx].uv if uv2_layer else (0.0, 0.0)
            
            log_print(f"vertex {co.x:.8f} {co.y:.8f} {co.z:.8f} {uv_val1[0]:.8f} {uv_val1[1]:.8f} {uv_val2[0]:.8f} {uv_val2[1]:.8f}")
else:
    log_print("Please select an active mesh object.")