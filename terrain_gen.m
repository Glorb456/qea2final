function [X, Y, Z, PX, PY] = terrain_gen(seed, complexity, amplitude)
%TERRAIN_GEN Compatibility wrapper for the terrain generator.

    [X, Y, Z, PX, PY] = generate_rover_terrain(seed, complexity, amplitude);
end
