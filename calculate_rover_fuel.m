function total_fuel = calculate_rover_fuel(path, X, Y, PX, PY)
    base_cost_per_m = 0.5; % Fuel spent just to roll 1 meter on the surface
    total_fuel = 0;

    if isempty(path) || size(path, 2) < 2
        return;
    end
    if size(path, 1) < 2
        error('Path must contain at least x and y rows.');
    end

    for i = 1:(size(path, 2) - 1)
        p1_xy = path(1:2, i);
        p2_xy = path(1:2, i+1);

        if size(path, 1) >= 3
            p1 = path(1:3, i);
            p2 = path(1:3, i+1);
            dist = norm(p2 - p1);
            height_change = p2(3) - p1(3);
        else
            dr_xy = p2_xy - p1_xy;
            dist = norm(dr_xy);

            gx = interp2(X, Y, PX, p1_xy(1), p1_xy(2));
            gy = interp2(X, Y, PY, p1_xy(1), p1_xy(2));
            height_change = dot([gx; gy], dr_xy);
        end

        if dist > 0
            step_fuel = (base_cost_per_m * dist) + max(0, height_change);
            total_fuel = total_fuel + step_fuel;
        end
    end
end
