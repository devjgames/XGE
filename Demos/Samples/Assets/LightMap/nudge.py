import bpy

# nudge(pixels / textureDimension, dotProductCutoff)
#

class Edge:
    def __init__(self, index):
        self.index = index
        self.pair = -1
        self.next = -1
        self.vertex = -1
        self.face = -1
        self.textureCoordinate = None

class Face:
    def __init__(self, index):
        self.index = index
        self.edge = -1
        self.polygon = -1

def nudge(amount, cutoff, mesh):
    edges = [] 
    vertices = []
    faces = []
    edgePairs = {}
    for i in range(0, len(mesh.polygons)):
        p = mesh.polygons[i]
        if len(p.loop_indices) == 4:
            face = Face(len(faces))
            face.polygon = i
            for j in range(0, 4):
                edge = Edge(len(edges))
                edge.vertex = mesh.loops[p.loop_indices[j]].vertex_index
                edge.face = face.index
                edge.textureCoordinate = mesh.uv_layers[0].uv[p.loop_indices[j]].vector
                if j == 0:
                    face.edge = edge.index
                else:
                    edges[edge.index - 1].next = edge.index
                    edge.prev = edge.index - 1
                    if j == 3:
                        edge.next = face.edge
                edges.append(edge)
            faces.append(face)
            for j in range(0, 4):
                v1 = edges[face.edge + j].vertex
                v2 = edges[face.edge + ((j + 1) % 4)].vertex
                if v1 > v2:
                    temp = v1
                    v1 = v2
                    v2 = temp
                key = str(v1) + ":" + str(v2)
                edge = edges[face.edge + j]
                if key in edgePairs:
                    pair = edges[edgePairs[key]]
                    if pair.pair != -1:
                        print("already has a pair")
                    else:
                        pair.pair = edge.index
                        edge.pair = pair.index
                else:
                    edgePairs[key] = edge.index
        else:
            print("not quad geometry")
    for edge in edges:
        f1 = faces[edge.face]
        if edge.pair == -1:
            print("pair not found")
            continue
        f2 = faces[edges[edge.pair].face]
        p1 = mesh.polygons[f1.polygon]
        p2 = mesh.polygons[f2.polygon]
        n1 = p1.normal
        n2 = p2.normal
        if n1.x * n2.x + n1.y * n2.y + n1.z * n2.z > cutoff:
            t1 = edge.textureCoordinate
            t2 = edges[edge.next].textureCoordinate
            if abs(t1.x - t2.x) < 0.0000001:
                if t1.x < 0.0000001:
                    t1.x += amount 
                    t2.x += amount
                else:
                    t1.x -= amount
                    t2.x -= amount
            elif abs(t1.y - t2.y) < 0.0000001:
                if t1.y < 0.0000001:
                    t1.y += amount
                    t2.y += amount
                else:
                    t1.y -= amount
                    t2.y -= amount
            else:
                print("tex " + str(t1.x) + ", " + str(t1.y) + " -> " + str(t2.x) + ", " + str(t2.y))
                
map = [
    [
        "***-----",
        "***-----",
        "***-----",
        "--------",
        "-----***",
        "-----***",
        "-----***"
    ],
    [
        "***-----",
        "***-----",
        "******--",
        "-----*--",
        "-----***",
        "-----***",
        "-----***"
    ]
]
visited = {}
keyedVertices = {}
vertices = []
uvs = []
faces = []

def blocked(x,y,z):
    if z < 0 or z >= len(map):
        return True
    if y < 0 or y >= len(map[z]):
        return True
    if x < 0 or x >= len(map[z][y]):
        return True
    return map[z][y][x] == '-'

def keyFor(x, y, z):
    return str(z) + ":" + str(y) + ":" + str(x)

def addVertex(x, y, z):
    key = keyFor(x, y, z)
    if key in keyedVertices:
        return keyedVertices[key]
    keyedVertices[key] = len(vertices)
    vertices.append((x, y, z))
    return keyedVertices[key]

def traverse(x,y,z):
    if blocked(x,y,z):
        return
    
    key = keyFor(x, y, z)
    if key in visited:
        return
    visited[key] = True
    
    if blocked(x - 1, y, z):
        a = addVertex(x, y,     z)
        b = addVertex(x, y + 1, z)
        c = addVertex(x, y + 1, z + 1)
        d = addVertex(x, y, z + 1)
        faces.append((a, b, c, d))
        uvs.append((0, 0))
        uvs.append((1, 0))
        uvs.append((1, 1))
        uvs.append((0, 1))
    if blocked(x + 1, y, z):
        a = addVertex(x + 1, y,     z)
        b = addVertex(x + 1, y,     z + 1)
        c = addVertex(x + 1, y + 1, z + 1)
        d = addVertex(x + 1, y + 1, z)
        faces.append((a, b, c, d))
        uvs.append((0, 0))
        uvs.append((0, 1))
        uvs.append((1, 1))
        uvs.append((1, 0))
    if blocked(x, y - 1, z):
        a = addVertex(x,     y, z)
        b = addVertex(x,     y, z + 1)
        c = addVertex(x + 1, y, z + 1)
        d = addVertex(x + 1, y, z)
        faces.append((a, b, c, d))
        uvs.append((0, 0))
        uvs.append((0, 1))
        uvs.append((1, 1))
        uvs.append((1, 0))
    if blocked(x, y + 1, z):
        a = addVertex(x,     y + 1, z)
        b = addVertex(x + 1, y + 1, z)
        c = addVertex(x + 1, y + 1, z + 1)
        d = addVertex(x,     y + 1, z + 1)
        faces.append((a, b, c, d))
        uvs.append((0, 0))
        uvs.append((1, 0))
        uvs.append((1, 1))
        uvs.append((0, 1))
    if blocked(x, y, z - 1):
        a = addVertex(x,     y,     z)
        b = addVertex(x + 1, y,     z)
        c = addVertex(x + 1, y + 1, z)
        d = addVertex(x,     y + 1, z)
        faces.append((a, b, c, d))
        uvs.append((0, 0))
        uvs.append((0, 1))
        uvs.append((1, 1))
        uvs.append((1, 0))
    if blocked(x, y, z + 1):
        a = addVertex(x,     y,     z + 1)
        b = addVertex(x,     y + 1, z + 1)
        c = addVertex(x + 1, y + 1, z + 1)
        d = addVertex(x + 1, y,     z + 1)
        faces.append((a, b, c, d))
        uvs.append((0, 0))
        uvs.append((0, 1))
        uvs.append((1, 1))
        uvs.append((1, 0))
        
    traverse(x - 1, y, z)
    traverse(x + 1, y, z)
    traverse(x, y - 1, z)
    traverse(x, y + 1, z)
    traverse(x, y, z - 1)
    traverse(x, y, z + 1)
         
traverse(0, 0, 0)

mesh = bpy.data.meshes.new("map")
mesh.from_pydata(vertices, [], faces)
mesh.update()

uvLayer = mesh.uv_layers.new(name="UVMap")
for i, uvLoop in enumerate(uvLayer.data):
    uvLoop.uv = uvs[i]
    
obj = bpy.data.objects.new("map", mesh)

cc = bpy.context.collection
cc.objects.link(obj)

bpy.context.view_layer.objects.active = obj
                
nudge(4 / 128.0, 0.1, obj.data)

print("done")

    
