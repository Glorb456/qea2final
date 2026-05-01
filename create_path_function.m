
function path = create_path_function(X,Y,Z)

    %with controller connected, move with left joystick, press A to speed
    %up, B to slow down, Y to exit/complete

    % axes(1) and axes(2) -> Left stick X and Y (-1.0 to 1.0)
    % axes(4) and axes(5) -> Right stick X and Y (-1.0 to 1.0)
    % buttons(1) -> A, buttons(2) -> B, buttons(3) -> X, buttons(4) -> Y
    

    joy = sim3d.io.Joystick(ID=1);
    
    figure('Name', 'Rover Mission: Driving Phase');
    surf(X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.8); 
    colormap summer; lighting gouraud; camlight;
    hold on;
    grid on;
    camproj('perspective');
    camup([0 0 1]);
    camva(75); 
    axis equal;
    start_z = interp2(X, Y, Z, 0, 0);
    hLine = animatedline('Color', 'b', 'LineWidth', 3);
    hMarker = plot3(0, 0, start_z, 'r*', 'MarkerSize', 12, 'LineWidth', 2); 
    
    goal_z = interp2(X, Y, Z, 10, 10);
    plot3(10, 10, goal_z, 'p', 'MarkerSize', 20, 'MarkerFaceColor', 'red');

   
    
    curr_x = 0;
    curr_y = 0; 
    addpoints(hLine, curr_x, curr_y, start_z)
    
    
    path = [0;0;0];
    pitch = 0; 
    yaw = 90;
    eye_height = .8; 
    look_speed = 2; 
    look_dist = 5; 
    curr_z = start_z; 
    
    while true
        % Read the current state of the controller
        [axes, buttons, ~] = read(joy);
        speed = .1;
        if buttons(1) == 1
            speed = .2;
        end 
        if buttons(2) == 1
            speed = .05;
        end 

        if abs(axes(4)) > 0.05
            yaw = yaw - axes(4) * look_speed; 
        end 
        if abs(axes(5)) > .05
            pitch = pitch - axes(5) *look_speed;
            pitch = max(min(pitch, 85), -85); 
        end 

    
    
        if sqrt(axes(1).^2+axes(2).^2) > .05
            % the_angle = atan2d(-axes(2), -axes(1)) - 90;
            % curr_y = curr_y +  speed*cosd(the_angle);
            % curr_x = curr_x + speed*sind(the_angle);
            % curr_z = interp2(X, Y, Z, curr_x, curr_y);
            move_fwd = -axes(2)*speed; 
            move_side = axes(1)*speed; 

            dx = (move_fwd*cosd(yaw))+(move_side*cosd(90-yaw)); 
            dy = (move_fwd*sind(yaw))+(move_side*sind(90-yaw));

            curr_x = curr_x + dx;
            curr_y = curr_y + dy;
            curr_x = max(min(curr_x, 10), -10);
            curr_y = max(min(curr_y, 10), -10);
            curr_z = interp2(X, Y, Z, curr_x, curr_y);




    
            addpoints(hLine, curr_x, curr_y, curr_z)
            hMarker.XData = curr_x;
            hMarker.YData = curr_y;
            hMarker.ZData = curr_z;

            
            path(:, end+1, :) = [curr_x; curr_y; curr_z ]; %#ok<AGROW>

        else 
            disp(0)
        end 
        campos([curr_x, curr_y, curr_z + eye_height]);
        target_x = curr_x + look_dist*cosd(pitch)*cosd(yaw);
        target_y = curr_y + look_dist*cosd(pitch)*sind(yaw);
        target_z = curr_z + eye_height + look_dist*sind(pitch); 
        camtarget([target_x, target_y, target_z])
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
    plot3(path(1, :), path(2,:), path(3,:), 'Color','g', 'LineWidth', 2)
end 

