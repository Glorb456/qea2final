
function path = create_path_function(X,Y,Z)

    %with controller connected, move with left joystick, press A to speed
    %up, B to slow down, Y to exit/complete

    % axes(1) and axes(2) -> Left stick X and Y (-1.0 to 1.0)
    % axes(4) and axes(5) -> Right stick X and Y (-1.0 to 1.0)
    % buttons(1) -> A, buttons(2) -> B, buttons(3) -> X, buttons(4) -> Y
    

    joy = sim3d.io.Joystick(ID=1);
    
    figure('Name', 'Rover Mission: Driving Phase');
    % MODIFICATION: Draw the terrain
    contour(X, Y, Z, 15); 
    hold on;
    axis equal;
    axis([-11 11 -11 11]);
    hLine = animatedline('Color', 'b', 'LineWidth', 2);
    hMarker = plot(0, 0, 'r*');
    % Goal location
    plot(10, 10, 'p', 'MarkerSize', 20, 'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'k');

   
    
    curr_x = 0;
    curr_y = 0; 
    addpoints(hLine, curr_x, curr_y)
    
    
    path = [0;0];
    
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
    
    
        if sqrt(axes(1).^2+axes(2).^2) > .05
            the_angle = atan2d(-axes(2), -axes(1)) - 90;
            curr_y = curr_y +  speed*cosd(the_angle);
            curr_x = curr_x + speed*sind(the_angle);
            path(:, end+1) = [curr_x; curr_y];
    
            disp(the_angle)
            addpoints(hLine, curr_x, curr_y)
            hMarker.XData = curr_x;
            hMarker.YData = curr_y;
            drawnow limitrate; 
            disp(the_angle)
        else 
            disp(0)
        end 
        if buttons(4) == 1
            disp('Exiting...');
            break;
        end 
        speed = .1;
    
        pause(0.01); 
        if buttons(3) == 1
            path = create_path_function(X, Y, Z);
            return
        end 
    end
    plot(path(1, :), path(2,:), 'Color','g', 'LineWidth', 2)
end 

