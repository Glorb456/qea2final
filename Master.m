clc; clear; close all;

filename = 'leaderboard_data.mat';
if isfile(filename), load(filename);
else, saved_seeds = []; saved_complexities = []; saved_amplitudes = []; end

fprintf('=== Welcome to the Rover Fuel Optimization Challenge ===\n');
mode = input('Choose Mode: [1] New Terrain | [2] Play Seed from Leaderboard: ');

if mode == 2 && ~isempty(saved_seeds)
    T = table(saved_seeds, saved_complexities, saved_amplitudes, 'VariableNames', {'Seed', 'Complexity', 'Amplitude'});
    disp(T);
    choice = input('Enter the Seed you want to play: ');
    idx = find(saved_seeds == choice, 1);
    seed = saved_seeds(idx); complexity = saved_complexities(idx); amplitude = saved_amplitudes(idx);
else
    seed = randi(10000); complexity = 0.5; amplitude = 10;
end

fig = figure('Color', 'w', 'Name', 'Terrain Designer', 'Position', [100, 100, 1000, 700]);
ax = axes('Parent', fig, 'Position', [0.13, 0.3, 0.77, 0.6]);

sld_comp = uicontrol('Parent', fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.3, 0.15, 0.4, 0.05], 'Value', complexity, 'Min', 0.1, 'Max', 1.0);
sld_amp = uicontrol('Parent', fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.3, 0.05, 0.4, 0.05], 'Value', amplitude, 'Min', 1, 'Max', 15);

uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.8, 0.05, 0.15, 0.1], ...
    'String', 'Save & Start', 'Callback', 'set(gcbf, ''UserData'', true); uiresume(gcbf)');

set(fig, 'UserData', false);
final_c = complexity;
final_a = amplitude;

while ishandle(fig) && ~get(fig, 'UserData')
    final_c = sld_comp.Value;
    final_a = sld_amp.Value;
    % Call terrain function in real-time
    [preview_x, preview_y, preview_z] = generate_rover_terrain(seed, sld_comp.Value, sld_amp.Value);

    cla(ax);
    surf(ax, preview_x, preview_y, preview_z, 'EdgeColor', 'none');
    colormap summer; colorbar; lighting gouraud; camlight;
    title(ax, sprintf('Seed: %d | Comp: %.2f | Amp: %.2f', seed, sld_comp.Value, sld_amp.Value));
    zlim([-35 35]);
    drawnow;

    uiwait(fig, 0.1);
end

if ~ishandle(fig)
    error('Terrain designer was closed before the mission started.');
end

[x, y, z, px, py] = generate_rover_terrain(seed, final_c, final_a);
close(fig);

% Save Data
saveAndQuit(filename, seed, final_c, final_a);

% Mission Phase
start_point = [-10; -10];
goal_point = [10; 10];

% Get the path from the joystick controller
player_path = create_path_function(x, y, z);

% Calculate final fuel using the independent physics function
final_fuel = calculate_rover_fuel(player_path, x, y, px, py);

% Find the best route only after the player finishes
status_fig = showStatusMessage('Finding best route...');
[best_path, best_fuel] = find_best_route(x, y, z, px, py, start_point, goal_point);
if ishandle(status_fig)
    close(status_fig);
end

showRouteComparison(x, y, z, player_path, best_path, final_fuel, best_fuel);

% Shared Functions
function saveAndQuit(fname, s, c, a)
    if isfile(fname)
        saved_data = load(fname);
        saved_seeds = getSavedField(saved_data, 'saved_seeds');
        saved_complexities = getSavedField(saved_data, 'saved_complexities');
        saved_amplitudes = getSavedField(saved_data, 'saved_amplitudes');
    else
        saved_seeds=[]; saved_complexities=[]; saved_amplitudes=[];
    end
    saved_seeds = [saved_seeds; s];
    saved_complexities = [saved_complexities; c];
    saved_amplitudes = [saved_amplitudes; a];
    save(fname, 'saved_seeds', 'saved_complexities', 'saved_amplitudes');
end

function value = getSavedField(saved_data, field_name)
    if isfield(saved_data, field_name)
        value = saved_data.(field_name);
    else
        value = [];
    end
end

function fig = showStatusMessage(message)
    fig = figure('Color', 'w', 'Name', 'Mission Status', ...
        'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off', ...
        'Position', [520 420 360 140]);
    axes('Parent', fig, 'Visible', 'off', 'Position', [0 0 1 1]);
    text(0.5, 0.55, message, 'Units', 'normalized', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 14, 'FontWeight', 'bold');
    drawnow;
end

function showRouteComparison(X, Y, Z, player_path, best_path, player_fuel, best_fuel)
    figure('Color', 'w', 'Name', 'Player Route vs Best Route');
    ax3d = axes('Position', [0.07 0.12 0.58 0.75]);
    hTerrain = surf(ax3d, X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.85);
    colormap(ax3d, summer); colorbar(ax3d); lighting(ax3d, 'gouraud'); camlight(ax3d);
    hold(ax3d, 'on'); grid(ax3d, 'on'); axis(ax3d, 'equal'); view(ax3d, 3);
    xlabel(ax3d, 'x position'); ylabel(ax3d, 'y position'); zlabel(ax3d, 'height');
    title(ax3d, 'Mission Complete: Player Route vs Computed Best Route');

    player3d = pathTo3D(player_path, X, Y, Z);
    best3d = pathTo3D(best_path, X, Y, Z);

    hPlayer = plot3(ax3d, player3d(1, :), player3d(2, :), player3d(3, :) + 0.35, ...
        'b-', 'LineWidth', 2.5);
    hBest = plot3(ax3d, best3d(1, :), best3d(2, :), best3d(3, :) + 0.65, ...
        'm--', 'LineWidth', 2.5);
    start_xy = player3d(1:2, 1);
    goal_xy = best3d(1:2, end);
    x_limits = [min(X(:)), max(X(:))];
    y_limits = [min(Y(:)), max(Y(:))];

    hStart = plot3(ax3d, start_xy(1), start_xy(2), interp2(X, Y, Z, start_xy(1), start_xy(2)) + 1.0, ...
        'go', 'MarkerFaceColor', 'g', 'MarkerSize', 9);
    hGoal = plot3(ax3d, goal_xy(1), goal_xy(2), interp2(X, Y, Z, goal_xy(1), goal_xy(2)) + 1.0, ...
        'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 14);

    legend(ax3d, [hTerrain, hPlayer, hBest, hStart, hGoal], ...
        {'Terrain', 'Player route', 'Best route', 'Start', 'Goal'}, ...
        'Location', 'northoutside');

    ax2d = axes('Position', [0.70 0.52 0.24 0.28]);
    contourf(ax2d, X, Y, Z, 16, 'LineColor', 'none');
    colormap(ax2d, summer);
    hold(ax2d, 'on'); axis(ax2d, 'equal'); axis(ax2d, [x_limits y_limits]);
    title(ax2d, '2D best-route map');
    xlabel(ax2d, 'x'); ylabel(ax2d, 'y');
    plot(ax2d, player3d(1, :), player3d(2, :), 'b-', 'LineWidth', 2);
    plot(ax2d, best3d(1, :), best3d(2, :), 'm--', 'LineWidth', 2.4);
    plot(ax2d, start_xy(1), start_xy(2), 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
    plot(ax2d, goal_xy(1), goal_xy(2), 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 7);

    axText = axes('Position', [0.70 0.17 0.24 0.25], 'Visible', 'off');
    ratio = player_fuel / max(best_fuel, eps);
    result_text = {
        'Mission Complete'
        ''
        sprintf('Player fuel: %.2f J', player_fuel)
        sprintf('Best-route fuel: %.2f J', best_fuel)
        sprintf('Player / best: %.1f%%', 100 * ratio)
        sprintf('Extra fuel: %.1f%%', 100 * (ratio - 1))
    };
    text(axText, 0, 1, result_text, 'Units', 'normalized', ...
        'VerticalAlignment', 'top', 'FontSize', 11, 'FontWeight', 'bold');
end

function path3d = pathTo3D(path, X, Y, Z)
    if size(path, 1) >= 3
        path3d = path(1:3, :);
        return;
    end

    z_values = interp2(X, Y, Z, path(1, :), path(2, :));
    path3d = [path(1:2, :); z_values];
end
%%
