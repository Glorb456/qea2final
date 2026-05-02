
function path = create_path_function(X,Y,Z)

    %with controller connected, move with left joystick, press A to speed
    %up, B to slow down, Y to exit/complete

    % axes(1) and axes(2) -> Left stick X and Y (-1.0 to 1.0)
    % axes(4) and axes(5) -> Right stick X and Y (-1.0 to 1.0)
    % buttons(1) -> A, buttons(2) -> B, buttons(3) -> X, buttons(4) -> Y
    

    % if nargin < 4
    %     best_path = [];
    % end

    joy = sim3d.io.Joystick(ID=1);

    mission_fig = figure('Name', 'Rover Mission: Driving Phase');
    ax3d = axes('Parent', mission_fig, 'Position', [0.05 0.06 0.9 0.9]);
    surf(ax3d, X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
    colormap(mission_fig, summer); lighting(ax3d, 'gouraud'); camlight(ax3d);
    hold(ax3d, 'on');
    grid(ax3d, 'on');
    camproj(ax3d, 'perspective');
    camup(ax3d, [0 0 1]);
    camva(ax3d, 75);
    axis(ax3d, 'equal');
    start_z = interp2(X, Y, Z, 0, 0);
    %hLine = animatedline(ax3d, 'Color', 'b', 'LineWidth', 3);
    %hMarker = plot3(ax3d, 0, 0, start_z, 'r*', 'MarkerSize', 12, 'LineWidth', 2);

    goal_z = interp2(X, Y, Z, 10, 10);
    plot3(ax3d, 10, 10, goal_z, 'p', 'MarkerSize', 20, 'MarkerFaceColor', 'red');
    % if ~isempty(best_path)
    %     plot3(ax3d, best_path(1, :), best_path(2, :), best_path(3, :) + 0.45, ...
    %         'm--', 'LineWidth', 2);
    % end

    map_ax = axes('Parent', mission_fig, 'Position', [0 0.065 0.3 0.3], ...
        'Color', [0.96 0.98 0.94], 'Box', 'on');
    contour(map_ax, X, Y, Z, 12, 'LineColor', [0.70 0.78 0.62]);
    hold(map_ax, 'on');
    axis(map_ax, 'equal');
    axis(map_ax, [-10 10 -10 10]);
    set(map_ax, 'XTick', [], 'YTick', [], 'Layer', 'top');
    title(map_ax, '2D Route Map', 'FontSize', 9);
    % if ~isempty(best_path)
    %     plot(map_ax, best_path(1, :), best_path(2, :), 'm--', 'LineWidth', 2);
    % end
    map_player_line = plot(map_ax, 0, 0, 'b-', 'LineWidth', 2);
    map_marker = plot(map_ax, 0, 0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
    plot(map_ax, 0, 0, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
    plot(map_ax, 10, 10, 'rp', 'MarkerFaceColor', 'r', 'MarkerSize', 7);

   
    
    curr_x = 0;
    curr_y = 0; 
    %addpoints(hLine, curr_x, curr_y, start_z)
    
    
    path = [0;0;start_z];
    pitch = 0; 
    yaw = 90;
    eye_height = .8; 
    look_speed = 2; 
    look_dist = 5; 
    curr_z = start_z; 
    
    while true
        % Read the current state of the controller
        [stick_axes, buttons, ~] = read(joy);
        speed = .1;
        if buttons(1) == 1
            speed = .2;
        end 
        if buttons(2) == 1
            speed = .05;
        end 

        if abs(stick_axes(4)) > 0.05
            yaw = yaw - stick_axes(4) * look_speed;
        end 
        if abs(stick_axes(5)) > .05
            pitch = pitch - stick_axes(5) *look_speed;
            pitch = max(min(pitch, 85), -85); 
        end 

    
    
        if sqrt(stick_axes(1).^2+stick_axes(2).^2) > .05
            % the_angle = atan2d(-axes(2), -axes(1)) - 90;
            % curr_y = curr_y +  speed*cosd(the_angle);
            % curr_x = curr_x + speed*sind(the_angle);
            % curr_z = interp2(X, Y, Z, curr_x, curr_y);
            move_fwd = -stick_axes(2)*speed;
            move_side = stick_axes(1)*speed;

            dx = (move_fwd*cosd(yaw))+(move_side*cosd(90-yaw)); 
            dy = (move_fwd*sind(yaw))+(move_side*sind(90-yaw));

            curr_x = curr_x + dx;
            curr_y = curr_y + dy;
            curr_x = max(min(curr_x, 10), -10);
            curr_y = max(min(curr_y, 10), -10);
            curr_z = interp2(X, Y, Z, curr_x, curr_y);




    
            %addpoints(hLine, curr_x, curr_y, curr_z)
            %hMarker.XData = curr_x;
            %hMarker.YData = curr_y;
            %hMarker.ZData = curr_z;

            
            path(:, end+1) = [curr_x; curr_y; curr_z ]; %#ok<AGROW>
            set(map_player_line, 'XData', path(1, :), 'YData', path(2, :));
            set(map_marker, 'XData', curr_x, 'YData', curr_y);

        else 
            disp(0)
        end 
        campos(ax3d, [curr_x, curr_y, curr_z + eye_height]);
        target_x = curr_x + look_dist*cosd(pitch)*cosd(yaw);
        target_y = curr_y + look_dist*cosd(pitch)*sind(yaw);
        target_z = curr_z + eye_height + look_dist*sind(pitch); 
        camtarget(ax3d, [target_x, target_y, target_z])
        drawnow limitrate; 


        
        if buttons(4) == 1
            disp('Exiting...');
            break;
        end 
        if sqrt((curr_x-10).^2 + (curr_y-10).^2) < .5
            break;
        end 
        pause(0.01); 
        if buttons(3) == 1
            path = create_path_function(X, Y, Z);
            return
        end 
    end
    plot3(ax3d, path(1, :), path(2,:), path(3,:), 'Color','g', 'LineWidth', 2)
end 

