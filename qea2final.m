% '1' represents the first connected game controller
joy = vrjoystick(1);


disp('Press the B button to exit...');

while true
    % Read the current state of the controller
    [axes, buttons, povs] = read(joy);
    
    % axes(1) and axes(2) -> Left stick X and Y (-1.0 to 1.0)
    % axes(4) and axes(5) -> Right stick X and Y (-1.0 to 1.0)
    % buttons(1) -> A, buttons(2) -> B, buttons(3) -> X, buttons(4) -> Y
    
    % Example: Print the Left Stick X-axis
    % fprintf('Left Stick X: %.2f\n', axes(1));
    if axes(1) > .5
        disp("Right")
    end 
    if axes(2) > .5
        disp("Back")
    end
    if axes(1) < -.5
        disp("Left")
    end 
    if axes(2) < -.5
        disp("Forward")
    end 
    if buttons(1) == 1
        disp("ACTION!")
    end
    if buttons(2) == 1
        disp('Exiting...');
        break;
    end
    pause(0.05); 
end