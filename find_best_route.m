function [best_path, best_fuel, cost_map] = find_best_route(X, Y, Z, PX, PY, start_point, goal_point)
%FIND_BEST_ROUTE Find a low-fuel route across the terrain grid.
%   Uses Dijkstra search with the same local fuel rule as
%   calculate_rover_fuel: flat rolling cost plus uphill work from the
%   terrain gradient.

    if nargin < 6 || isempty(start_point)
        start_point = [0; 0];
    end
    if nargin < 7 || isempty(goal_point)
        goal_point = [10; 10];
    end

    start_point = start_point(1:2);
    goal_point = goal_point(1:2);

    [nRows, nCols] = size(Z);
    start_idx = nearestGridIndex(X, Y, start_point);
    goal_idx = nearestGridIndex(X, Y, goal_point);

    cost_map = inf(nRows, nCols);
    visited = false(nRows, nCols);
    previous = zeros(nRows, nCols);
    cost_map(start_idx) = 0;

    neighbors = [
        -1  0
         1  0
         0 -1
         0  1
        -1 -1
        -1  1
         1 -1
         1  1
    ];

    while true
        candidates = cost_map;
        candidates(visited) = inf;
        [current_cost, current_idx] = min(candidates(:));

        if isinf(current_cost) || current_idx == goal_idx
            break;
        end

        visited(current_idx) = true;
        [row, col] = ind2sub([nRows, nCols], current_idx);

        for k = 1:size(neighbors, 1)
            new_row = row + neighbors(k, 1);
            new_col = col + neighbors(k, 2);

            if new_row < 1 || new_row > nRows || new_col < 1 || new_col > nCols
                continue;
            end
            if visited(new_row, new_col)
                continue;
            end

            step_cost = routeStepFuel(X, Y, Z, row, col, new_row, new_col);
            new_cost = current_cost + step_cost;

            if new_cost < cost_map(new_row, new_col)
                cost_map(new_row, new_col) = new_cost;
                previous(new_row, new_col) = current_idx;
            end
        end
    end

    if isinf(cost_map(goal_idx))
        best_path = [start_point, goal_point];
        best_path = pathTo3D(best_path, X, Y, Z);
        best_fuel = calculate_rover_fuel(best_path, X, Y, PX, PY);
        return;
    end

    route_indices = goal_idx;
    current_idx = goal_idx;
    while current_idx ~= start_idx
        current_idx = previous(current_idx);
        if current_idx == 0
            break;
        end
        route_indices = [current_idx; route_indices]; %#ok<AGROW>
    end

    best_path = zeros(3, numel(route_indices));
    for i = 1:numel(route_indices)
        idx = route_indices(i);
        best_path(:, i) = [X(idx); Y(idx); Z(idx)];
    end
    best_fuel = calculate_rover_fuel(best_path, X, Y, PX, PY);
end

function idx = nearestGridIndex(X, Y, point)
    [~, idx] = min((X(:) - point(1)).^2 + (Y(:) - point(2)).^2);
end

function step_fuel = routeStepFuel(X, Y, Z, row, col, new_row, new_col)
    base_cost_per_m = 0.5;
    p1 = [X(row, col); Y(row, col); Z(row, col)];
    p2 = [X(new_row, new_col); Y(new_row, new_col); Z(new_row, new_col)];
    dr = p2 - p1;
    dist = norm(dr);
    height_change = dr(3);

    step_fuel = (base_cost_per_m * dist) + max(0, height_change);
end

function path3d = pathTo3D(path2d, X, Y, Z)
    z_values = interp2(X, Y, Z, path2d(1, :), path2d(2, :));
    path3d = [path2d(1:2, :); z_values];
end
