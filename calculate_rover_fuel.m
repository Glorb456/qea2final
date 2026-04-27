function total_fuel = calculate_rover_fuel(path, X, Y, PX, PY)
    base_cost_per_m = 0.5; % Fuel spent just to roll 1 meter
    total_fuel = 0;

    for i = 1:(size(path, 2) - 1)
        p1 = path(:, i);
        p2 = path(:, i+1);
        
        % Calculate displacement vector
        dr = p2 - p1;
        dist = norm(dr);
        
        if dist > 0
            % get the gradient at the exact rover location
            gx = interp2(X, Y, PX, p1(1), p1(2));
            gy = interp2(X, Y, PY, p1(1), p1(2));
            grad_vector = [gx; gy];

            % Work = grad(f) · dr
            work_done = dot(grad_vector, dr);
            
            % Fuel Logic
            % the distance + the work done against gravity if uphill
            step_fuel = (base_cost_per_m * dist) + max(0, work_done);
            total_fuel = total_fuel + step_fuel;
        end
    end
end