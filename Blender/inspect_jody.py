import re

with open('I:/RobloxDev/Blender/JODY.fbx', 'rb') as f:
    content = f.read()

# Match models
limb_nodes = re.findall(rb'Model::(mixamorig[^\"]*)\", \"LimbNode\"', content)
print("FBX LimbNodes count:", len(limb_nodes))
if limb_nodes:
    print("Sample LimbNodes:", [l.decode() for l in limb_nodes[:5]])

# Also check Deformer / Cluster names (skinning weights in FBX)
clusters = re.findall(rb'Deformer::(Cluster[^\"]*)\", \"Cluster\"', content)
print("Clusters count:", len(clusters))

# Check SubDeformer names
subdeformers = re.findall(rb'SubDeformer::([^\"]*)', content)
print("Subdeformers count:", len(subdeformers))
if subdeformers:
    print("Sample subdeformers:", [s.decode() for s in subdeformers[:5]])
