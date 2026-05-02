
function path = create_path_function(X,Y,Z)

    %with controller connected, move with left joystick, press A to speed
    %up, B to slow down, Y to exit/complete

    % axes(1) and axes(2) -> Left stick X and Y (-1.0 to 1.0)
    % axes(4) and axes(5) -> Right stick X and Y (-1.0 to 1.0)
    % buttons(1) -> A, buttons(2) -> B, buttons(3) -> X, buttons(4) -> Y
    
    %initialize graphs and starting positions
    joy = sim3d.io.Joystick(ID=1);
    start_x = -10;
    start_y = -10;
    start_z = interp2(X, Y, Z, start_x, start_y);

    goal_x = 10;
    goal_y = 10;
    x_limits = [min(X(:)), max(X(:))];
    y_limits = [min(Y(:)), max(Y(:))];
    mission_fig = figure('Name', 'Rover Mission: Driving Phase');
    ax3d = axes('Parent', mission_fig, 'Position', [0 0 1 1]);
    annotation(mission_fig, "textbox", [0, 0.8, 0.2, 0.2], 'String', 'Controls: A: Speed up, B: Slow Down, X: Reset attempt', 'FitBoxToText', 'on', 'BackgroundColor', 'w');
    surf(ax3d, X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    colormap(mission_fig, summer); lighting(ax3d, 'gouraud'); camlight(ax3d);
    hold(ax3d, 'on');
    grid(ax3d, 'on');

    %initialize camera
    camproj(ax3d, 'perspective');
    camup(ax3d, [0 0 1]);
    camva(ax3d, 75);
    axis(ax3d, 'equal');

    %inittialize current positions
    curr_x = start_x;
    curr_y = start_y;
    curr_z = start_z;
    yaw = 90;

    %plot goal
    goal_z = interp2(X, Y, Z, goal_x, goal_y);
    plot3(ax3d, goal_x, goal_y, goal_z, 'p', 'MarkerSize', 20, 'MarkerFaceColor', 'red');

    %initialize and plot map
    map_ax = axes('Parent', mission_fig, 'Position', [0 0.065 0.3 0.3], ...
        'Color', [0.96 0.98 0.94], 'Box', 'on');
    contourf(map_ax, X, Y, Z, 12, 'LineColor', 'none');
    c = colorbar('southoutside');
    c.Label.String = 'Elevation';
    hold(map_ax, 'on');
    axis(map_ax, 'equal');
    axis(map_ax, [x_limits y_limits]);
    set(map_ax, 'XTick', [], 'YTick', [], 'Layer', 'top');
    title(map_ax, '2D Route Map', 'FontSize', 9);
    
    map_player_line = plot(map_ax, start_x, start_y, 'b-', 'LineWidth', 2);
    map_marker = plot(map_ax, start_x, start_y, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
    plot(map_ax, start_x, start_y, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
    plot(map_ax, goal_x, goal_y, 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
    heading_len = 1.35;
    heading_arrow = quiver(map_ax, curr_x, curr_y, heading_len*cosd(yaw), heading_len*sind(yaw), ...
        0, 'Color', [0.05 0.05 0.05], 'LineWidth', 2, 'MaxHeadSize', 1.4);    
    
    %initialize manual control
    path = [start_x; start_y; start_z];
    pitch = 0; 
    eye_height = .8; 
    look_speed = 2; 
    look_dist = 5; 
    
    %manual control loop
    while true
        % Read the current state of the controller
        [stick_axes, buttons, ~] = read(joy);
        speed = .075;

        %A - speed up
        if buttons(1) == 1
            speed = .15;
        end 

        %B - slow down
        if buttons(2) == 1
            speed = .05;
        end 
        
        %Looking around
        if abs(stick_axes(4)) > 0.05
            yaw = yaw - stick_axes(4) * look_speed;
        end 

        if abs(stick_axes(5)) > .05
            pitch = pitch - stick_axes(5) *look_speed;
            pitch = max(min(pitch, 85), -85); 
        end

        %movement
        if sqrt(stick_axes(1).^2+stick_axes(2).^2) > .05
            move_fwd = -stick_axes(2)*speed;
            move_side = stick_axes(1)*speed;

            dx = (move_fwd*cosd(yaw))+(move_side*cosd(90-yaw)); 
            dy = (move_fwd*sind(yaw))+(move_side*sind(90-yaw));

            curr_x = curr_x + dx;
            curr_y = curr_y + dy;
            curr_x = max(min(curr_x, x_limits(2)), x_limits(1));
            curr_y = max(min(curr_y, y_limits(2)), y_limits(1));
            curr_z = interp2(X, Y, Z, curr_x, curr_y);

            path(:, end+1) = [curr_x; curr_y; curr_z ]; %#ok<AGROW>
            set(map_player_line, 'XData', path(1, :), 'YData', path(2, :));
            set(map_marker, 'XData', curr_x, 'YData', curr_y);
        end 
        

        set(heading_arrow, 'XData', curr_x, 'YData', curr_y, ...
            'UData', heading_len*cosd(yaw), 'VData', heading_len*sind(yaw));
        
        %change camera position based on target
        campos(ax3d, [curr_x, curr_y, curr_z + eye_height]);
        target_x = curr_x + look_dist*cosd(pitch)*cosd(yaw);
        target_y = curr_y + look_dist*cosd(pitch)*sind(yaw);
        target_z = curr_z + eye_height + look_dist*sind(pitch); 
        camtarget(ax3d, [target_x, target_y, target_z])

        drawnow limitrate; 

        %reached goal
        if sqrt((curr_x-goal_x).^2 + (curr_y-goal_y).^2) < .5
            break;
        end 
        pause(0.01); 

        %X - Reset
        if buttons(3) == 1
            path = create_path_function(X, Y, Z);
            return
        end 
    end
    plot3(ax3d, path(1, :), path(2,:), path(3,:), 'Color','g', 'LineWidth', 2)
end 

