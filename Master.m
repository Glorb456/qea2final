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
    'Position', [0.3, 0.15, 0.4, 0.05], 'Value', complexity, 'Min', 0.1, 'Max', 2.0);
sld_amp = uicontrol('Parent', fig, 'Style', 'slider', 'Units', 'normalized', ...
    'Position', [0.3, 0.05, 0.4, 0.05], 'Value', amplitude, 'Min', 1, 'Max', 30);

uicontrol('Style', 'pushbutton', 'Units', 'normalized', 'Position', [0.8, 0.05, 0.15, 0.1], ...
    'String', 'Save & Start', 'Callback', 'uiresume(gcbf)');

while ishandle(fig)
    final_c = sld_comp.Value;
    final_a = sld_amp.Value;
    % Call terrain function in real-time
    [x, y, z, px, py] = generate_rover_terrain(seed, sld_comp.Value, sld_amp.Value);
    
    cla(ax);
    surf(ax, x, y, z, 'EdgeColor', 'none');
    colormap summer; colorbar; lighting gouraud; camlight;
    title(ax, sprintf('Seed: %d | Comp: %.2f | Amp: %.2f', seed, sld_comp.Value, sld_amp.Value));
    zlim([-35 35]);
    drawnow;
    
    uiwait(fig, 0.5); 
end

% Save Data
saveAndQuit(filename, seed, final_c, final_a);

% Mission Phase
fprintf('Starting Mission...\n');
% Get the path from the joystick controller
player_path = create_path_function(x, y, z);

% Calculate final fuel using the independent physics function
final_fuel = calculate_rover_fuel(player_path, x, y, px, py);

fprintf('\nMission Complete!\nTotal Fuel Used: %.2f Joules\n', final_fuel);

% Shared Functions
function saveAndQuit(fname, s, c, a)
    if isfile(fname), load(fname); 
    else, saved_seeds=[]; saved_complexities=[]; saved_amplitudes=[]; end
    saved_seeds = [saved_seeds; s];
    saved_complexities = [saved_complexities; c];
    saved_amplitudes = [saved_amplitudes; a];
    save(fname, 'saved_seeds', 'saved_complexities', 'saved_amplitudes');
end