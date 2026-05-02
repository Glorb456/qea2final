function [X, Y, Z, PX, PY] = generate_rover_terrain(seed, complexity, amplitude)
    [X, Y] = meshgrid(-10:0.2:10, -10:0.2:10);
    rng(seed); 
    phase1 = rand(1) * 2 * pi;
    phase2 = rand(1) * 2 * pi;
    phase3 = rand(1) * 2 * pi;
    freq1 = complexity * 0.5;
    freq2 = complexity * 1.5;
    Z = amplitude * (0.7 * sin(freq1 * X + phase1) .* cos(freq1 * Y + phase2) + 0.3 * sin(freq2 * X + phase3) .* cos(freq2 * Y + phase1));
    [PX, PY] = gradient(Z, 0.2, 0.2); 
end

%[appendix]{"version":"1.0"}
%---
