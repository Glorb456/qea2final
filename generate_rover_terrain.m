function [X, Y, Z, PX, PY] = generate_rover_terrain(seed, complexity, amplitude)
    [X, Y] = meshgrid(-10:0.2:10, -10:0.2:10);
    rng(seed); 
    p1 = rand * 2*pi; p2 = rand * 2*pi;
    Z = amplitude * (sin(complexity * X + p1) .* cos(complexity * Y + p2));
    [PX, PY] = gradient(Z, 0.2, 0.2); 
end

%[appendix]{"version":"1.0"}
%---
