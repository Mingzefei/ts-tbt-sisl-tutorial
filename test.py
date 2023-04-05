import sisl
import sisl.viz
import numpy as np
import matplotlib.pyplot as plt

graphene = sisl.geom.graphene()
# 用 sisl 搭建一个具有32个碳原子的graphene
graphene = graphene.tile(4, 0).tile(4, 1)
# plot the geometry
p = sisl.viz.plotly.graph_geometry(graphene)