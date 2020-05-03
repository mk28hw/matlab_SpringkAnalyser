classdef kAnalyser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        RobotArmkAnalyserUIFigure      matlab.ui.Figure
        UIAxes                         matlab.ui.control.UIAxes
        SliderLabel                    matlab.ui.control.Label
        Slider                         matlab.ui.control.Slider
        Spring1kEditFieldLabel         matlab.ui.control.Label
        Spring1kEditField              matlab.ui.control.NumericEditField
        Spring2kEditFieldLabel         matlab.ui.control.Label
        Spring2kEditField              matlab.ui.control.NumericEditField
        MaxWeightEditField_2Label      matlab.ui.control.Label
        MaxWeightEditField_2           matlab.ui.control.NumericEditField
        MaxWeightEditFieldLabel        matlab.ui.control.Label
        MaxWeightEditField_1           matlab.ui.control.NumericEditField
        TotalPayloadEditFieldLabel     matlab.ui.control.Label
        TotalPayloadEditField          matlab.ui.control.NumericEditField
        InitialWeightEditFieldLabel    matlab.ui.control.Label
        InitialWeightEditField         matlab.ui.control.NumericEditField
        kgLabel                        matlab.ui.control.Label
        kgLabel_2                      matlab.ui.control.Label
        NmLabel                        matlab.ui.control.Label
    end
   
    properties (Access = private)
        W_1 % Description
        W_2 % Description
        lineVerBlue
        lineVerRed
        lineHorDown
        lineHorUp
        fillGreyDown
        fillGreyUp
        m_4_max
        textVars
    end
    
    methods (Access = private)
        
        function updatePlot(app, i_1, i_2)
            % vertical lines
            k_1_calc = app.W_1(i_1, 1);
            k_2_calc = app.W_2(i_2, 1);
            % updating fields 
            app.MaxWeightEditField_1.Value = app.W_2(i_2, 3);
            app.MaxWeightEditField_2.Value = app.W_1(i_1, 3);
            app.Spring1kEditField.Value = k_1_calc;
            app.Spring2kEditField.Value = k_2_calc;
            max_w = min(app.W_1(i_1, 3),app.W_2(i_2, 3));
            min_w = max(app.W_1(i_1, 2),app.W_2(i_2, 2));
            dif_w = max_w - min_w;
            app.TotalPayloadEditField.Value = dif_w;
            app.InitialWeightEditField.Value = min_w;
            % updating vertical lines
            y = app.UIAxes.YLim;
            app.lineVerBlue.XData = [k_1_calc k_1_calc];
            app.lineVerRed.XData = [k_2_calc k_2_calc];
            app.lineHorDown.YData = [min_w min_w];
            app.lineHorUp.YData = [max_w max_w];
            app.fillGreyDown.YData = [min_w; min_w; 0; 0];
            app.fillGreyUp.YData = [y(2); y(2); max_w; max_w];
            % updating slider
            app.updateSlider(i_1);
            app.textVars.String = {    
                sprintf('m_{4p} = %.3f kg ^{ max pure payload }', dif_w),
                sprintf('m_{4i} = %.3f kg ^{ extra initial weight }', min_w),
                sprintf('m_{4t} = m_{4p} + m_{4i} = %.3f kg ^{ total payload }', max_w),
                sprintf('k_1 = %.3f N/m', k_1_calc),
                sprintf('k_2 = %.3f N/m', k_2_calc)};
        end
        
        function updateSlider(app, index)
            new_value = 100*app.W_1(index,2)/(app.W_1(end,2) - app.W_1(1,2));
            if new_value > app.Slider.Limits(1,2)
                app.Slider.Value = app.Slider.Limits(1,2);
            else
                app.Slider.Value = new_value;
            end
        end
        
        function results = getVarName(app, var)
            results = inputname(2);
        end
        
        function printVar(app, label_obj, name, var)
           label_obj.Text = sprintf('%s = %.3f', name, var);
        end
    end
    
    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.m_4_max = 100; % edit this to change max payload to test
            app.UIAxes.YLim = [0 app.m_4_max];
            % constants:
            g = 9.81; % acceleration due to gravity [m/s^2]
            % masses of arm links [kg]
            m_1 = 0.404;
            m_2 = 0.253;
            m_3 = 0.148;
            % legths of arm links [m]
            R_1 = 0.102;
            R_2 = 0.162;
            R_3 = 0.076;
            
            r_1 = 0.21;
            r_2 = 0.31;
            % arm back 1 and 2 [m]
            b_1 = 0.075;
            b_2 = 0.07; % d
            % linear actuator distance from the top (Spring 1 and 2) [m]
            c_1 = [0.150: 0.01: 0.25];
            c_2 = [0.150: 0.01: 0.25];
            % payload [kg]
            interval = 0.002;
            m_4 = [0: interval: app.m_4_max]';

            % calculating k constants values for 2 springs for given robot arm parameters:
            k_1 = (m_1 * R_1 + m_2 * r_1 + m_3 * R_3 + m_4 * r_1) * g ./ (b_1 .* c_1);
            k_2 = (m_2 * R_2 - m_3 * b_2 + m_4 * r_2) * g ./ (b_2 .* c_2);
            % calculating weight ranges for different k values:
            k_1_f = k_1(:,1);
            k_1_l = k_1(:,end);
            k_2_f = k_2(:,1);
            k_2_l = k_2(:,end);
            for i=1:numel(m_4)
                finder = find(k_1_l > k_1_f(i,1),1,'first');
                if (finder) 
                    W_1(i,1:4) = [k_1_f(i,1) i * interval finder * interval k_1_l(finder,1)];
                end
                finder = find(k_2_l > k_2_f(i,1),1,'first');
                if (finder) 
                    W_2(i,1:4) = [k_2_f(i,1) i * interval finder * interval k_2_l(finder,1)];
                end
            end
            % plotting
            
            plot(app.UIAxes, W_1(:,1), W_1(:,2), "LineWidth", 2, "Color",'b', "LineStyle",":");
            str = {
                sprintf('%s = %.3f',app.getVarName(m_1), m_1),
                sprintf('%s = %.3f',app.getVarName(m_2), m_2),
                sprintf('%s = %.3f',app.getVarName(m_3), m_3),
                sprintf('%s = %.3f',app.getVarName(R_1), R_1),
                sprintf('%s = %.3f',app.getVarName(R_2), R_2),
                sprintf('%s = %.3f',app.getVarName(R_3), R_3),
                sprintf('%s = %.3f',app.getVarName(r_1), r_1),
                sprintf('%s = %.3f',app.getVarName(r_2), r_2),
                sprintf('%s = %.3f',app.getVarName(b_1), b_1),
                sprintf('%s = %.3f',app.getVarName(b_2), b_2)};
            textCons = text((app.UIAxes.XLim(2) * 0.1), (app.UIAxes.YLim(2) * 0.425), str, 'Parent', app.UIAxes); 
            textCons.HorizontalAlignment = 'right'
            textCons.FontSize = 8;
            textCons.Color = 'k';
            text_1 = text(W_1(end,1), W_1(end,2), 'c_1 = 0.15', 'Parent', app.UIAxes); 
            text_1.HorizontalAlignment = 'left'
            text_1.FontSize = 10;
            text_1.Color = 'b';
            text_2 = text(W_2(end,1), W_2(end,2), 'c_2 = 0.15', 'Parent', app.UIAxes); 
            text_2.HorizontalAlignment = 'left'
            text_2.FontSize = 10;
            text_2.Color = 'r';
            text_3 = text(W_1(end,1), W_1(end,3), 'c_1 = 0.25', 'Parent', app.UIAxes); 
            text_3.HorizontalAlignment = 'left'
            text_3.FontSize = 10;
            text_3.Color = 'b';
            text_4 = text(W_2(end,1), W_2(end,3), 'c_2 = 0.25', 'Parent', app.UIAxes); 
            text_4.HorizontalAlignment = 'left'
            text_4.FontSize = 10;
            text_4.Color = 'r';
            app.textVars = text((app.UIAxes.XLim(2) * 0.25), (app.UIAxes.YLim(2) * 0.825), '', 'Parent', app.UIAxes); 
            app.textVars.HorizontalAlignment = 'left'
            app.textVars.FontSize = 9;
            app.textVars.Color = 'k';
            % min payload for k_1
            plot(app.UIAxes, W_1(:,1), W_1(:,3), "LineWidth", 2, "Color",'b');          
            % max payload for k_2
            plot(app.UIAxes, W_2(:,1), W_2(:,2), "LineWidth", 2, "Color",'r', "LineStyle",":");
            % min payload for k_2
            plot(app.UIAxes, W_2(:,1), W_2(:,3), "LineWidth", 2, "Color",'r');
            %hold on;
            x = W_1(:,1);
            y_l = W_1(:,3);
            y_h = W_1(:,2);
            
            fill(app.UIAxes, [x ; x(end:-1:1)], [y_l ; y_h(end:-1:1)],'b','EdgeAlpha', 0.0,'FaceAlpha',.25);
            
            x = W_2(:,1);
            y_l = W_2(:,3);
            y_h = W_2(:,2);

            fill(app.UIAxes, [x ; x(end:-1:1)], [y_l ; y_h(end:-1:1)],'r','EdgeAlpha', 0.0,'FaceAlpha',.25);
            app.W_1 = W_1;
            app.W_2 = W_2;
            x = app.UIAxes.XLim;
            y = app.UIAxes.YLim;
            % vertical lines
            app.lineVerBlue = plot(app.UIAxes, [0 0],[y(1) y(2)], "LineWidth", 0.5, "Color",'b', "LineStyle","--")
            app.lineVerRed = plot(app.UIAxes, [0 0],[y(1) y(2)], "LineWidth", 0.5, "Color",'r', "LineStyle","--")
            % horizontal lines
            app.lineHorDown = plot(app.UIAxes, [x(1) x(2)],[y(1) y(1)], "LineWidth", 0.25, "Color",'k', "LineStyle","--", "DisplayName","dupa")
            app.lineHorUp = plot(app.UIAxes, [x(1) x(2)],[y(1) y(1)], "LineWidth", 0.25, "Color",'k', "LineStyle","--")
            app.fillGreyDown = fill(app.UIAxes, [x(1); x(2); x(2); x(1)], [4; 4; y(1); y(1)],'k','EdgeAlpha', 0.0,'FaceAlpha',.15);
            app.fillGreyUp = fill(app.UIAxes, [x(1); x(2); x(2); x(1)], [y(2); y(2); 6; 6],'k','EdgeAlpha', 0.0,'FaceAlpha',.15);
            app.UIAxes.XLabel.Interpreter = 'latex';
            app.UIAxes.XLabel.String = 'spring constants, $k_1, k_2\ \left[N/m\right]$';
            app.UIAxes.YLabel.Interpreter = 'latex';
            app.UIAxes.YLabel.String = 'weight of the payload $ [kg]$';
            legend(app.UIAxes, {'k_1 @ min payload', 'k_1 @ max payload', 'k_2 @ min payload', 'k_2 @ max payload'},'Location','northwest', "FontSize", 9);
        end

        % Value changed function: Slider
        function SliderValueChanged(app, event)
            value = app.Slider.Value / 100
            
            tep_l = app.W_1(1,2)
            tep_h = app.W_1(end,2)
            i_1 = find(app.W_1(:,2) >= (tep_l + ((tep_h-tep_l)*value)), 1, "first");
            i_2 = find(app.W_2(:,2) >= app.W_2(i_1,2), 1, 'first');
            
            app.updatePlot(i_1, i_2);         
        end

        % Value changed function: Spring1kEditField
        function Spring1kEditFieldValueChanged(app, event)
            value = app.Spring1kEditField.Value;
            
            i_1 = find(app.W_1(:,1) >= value, 1, "first");
            i_2 = find(app.W_2(:,2) >= app.W_2(i_1,2), 1, 'first');
   
            app.updatePlot(i_1, i_2);         
        end

        % Value changed function: MaxWeightEditField_2
        function MaxWeightEditField_2ValueChanged(app, event)
            value = app.MaxWeightEditField_2.Value;
            
            i_1 = find(app.W_1(:,3) >= value, 1, "first");
            i_2 = find(app.W_2(:,2) >= app.W_2(i_1,2), 1, 'first');
   
            app.updatePlot(i_1, i_2);             
        end

        % Value changed function: Spring2kEditField
        function Spring2kEditFieldValueChanged(app, event)
            value = app.Spring2kEditField.Value;
            
            i_2 = find(app.W_2(:,1) >= value, 1, "first");
            i_1 = find(app.W_1(:,1) >= app.Spring1kEditField.Value, 1, 'first');
            
            app.updatePlot(i_1, i_2); 
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create RobotArmkAnalyserUIFigure and hide until all components are created
            app.RobotArmkAnalyserUIFigure = uifigure('Visible', 'off');
            app.RobotArmkAnalyserUIFigure.Position = [100 100 640 480];
            app.RobotArmkAnalyserUIFigure.Name = 'k-Analyser : Robot Arm Spring Balanced Constant k Analyser ';

            % Create UIAxes
            app.UIAxes = uiaxes(app.RobotArmkAnalyserUIFigure);
            title(app.UIAxes, 'range of payload (weight) for different spring constants, k_1, k_2')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            app.UIAxes.XLim = [0 18000];
            app.UIAxes.YLim = [0 10];
            app.UIAxes.GridAlpha = 0.2;
            app.UIAxes.MinorGridAlpha = 0.1;
            app.UIAxes.NextPlot = 'add';
            app.UIAxes.XGrid = 'on';
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YGrid = 'on';
            app.UIAxes.Position = [21 141 600 320];

            % Create SliderLabel
            app.SliderLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.SliderLabel.HorizontalAlignment = 'right';
            app.SliderLabel.Position = [217 90 25 22];
            app.SliderLabel.Text = '%';

            % Create Slider
            app.Slider = uislider(app.RobotArmkAnalyserUIFigure);
            app.Slider.ValueChangedFcn = createCallbackFcn(app, @SliderValueChanged, true);
            app.Slider.FontColor = [0 0 1];
            app.Slider.Position = [68 100 150 3];

            % Create Spring1kEditFieldLabel
            app.Spring1kEditFieldLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.Spring1kEditFieldLabel.HorizontalAlignment = 'right';
            app.Spring1kEditFieldLabel.FontColor = [0 0 1];
            app.Spring1kEditFieldLabel.Position = [259 90 60 22];
            app.Spring1kEditFieldLabel.Text = 'Spring 1 k';

            % Create Spring1kEditField
            app.Spring1kEditField = uieditfield(app.RobotArmkAnalyserUIFigure, 'numeric');
            app.Spring1kEditField.ValueDisplayFormat = '%10.4g';
            app.Spring1kEditField.ValueChangedFcn = createCallbackFcn(app, @Spring1kEditFieldValueChanged, true);
            app.Spring1kEditField.FontColor = [0 0 1];
            app.Spring1kEditField.Position = [334 90 68 22];

            % Create Spring2kEditFieldLabel
            app.Spring2kEditFieldLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.Spring2kEditFieldLabel.HorizontalAlignment = 'right';
            app.Spring2kEditFieldLabel.FontColor = [1 0 0];
            app.Spring2kEditFieldLabel.Position = [445 90 60 22];
            app.Spring2kEditFieldLabel.Text = 'Spring 2 k';

            % Create Spring2kEditField
            app.Spring2kEditField = uieditfield(app.RobotArmkAnalyserUIFigure, 'numeric');
            app.Spring2kEditField.ValueDisplayFormat = '%10.4g';
            app.Spring2kEditField.ValueChangedFcn = createCallbackFcn(app, @Spring2kEditFieldValueChanged, true);
            app.Spring2kEditField.FontColor = [1 0 0];
            app.Spring2kEditField.Position = [520 90 68 22];

            % Create MaxWeightEditField_2Label
            app.MaxWeightEditField_2Label = uilabel(app.RobotArmkAnalyserUIFigure);
            app.MaxWeightEditField_2Label.HorizontalAlignment = 'right';
            app.MaxWeightEditField_2Label.FontColor = [0 0 1];
            app.MaxWeightEditField_2Label.Position = [250 58 69 22];
            app.MaxWeightEditField_2Label.Text = 'Max Weight';

            % Create MaxWeightEditField_2
            app.MaxWeightEditField_2 = uieditfield(app.RobotArmkAnalyserUIFigure, 'numeric');
            app.MaxWeightEditField_2.ValueDisplayFormat = '%10.4g';
            app.MaxWeightEditField_2.ValueChangedFcn = createCallbackFcn(app, @MaxWeightEditField_2ValueChanged, true);
            app.MaxWeightEditField_2.FontColor = [0 0 1];
            app.MaxWeightEditField_2.Position = [334 58 68 22];

            % Create MaxWeightEditFieldLabel
            app.MaxWeightEditFieldLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.MaxWeightEditFieldLabel.HorizontalAlignment = 'right';
            app.MaxWeightEditFieldLabel.FontColor = [1 0 0];
            app.MaxWeightEditFieldLabel.Position = [436 58 69 22];
            app.MaxWeightEditFieldLabel.Text = 'Max Weight';

            % Create MaxWeightEditField_1
            app.MaxWeightEditField_1 = uieditfield(app.RobotArmkAnalyserUIFigure, 'numeric');
            app.MaxWeightEditField_1.ValueDisplayFormat = '%10.4g';
            app.MaxWeightEditField_1.Editable = 'off';
            app.MaxWeightEditField_1.FontColor = [1 0 0];
            app.MaxWeightEditField_1.BackgroundColor = [0.9412 0.9412 0.9412];
            app.MaxWeightEditField_1.Position = [520 58 68 22];

            % Create TotalPayloadEditFieldLabel
            app.TotalPayloadEditFieldLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.TotalPayloadEditFieldLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TotalPayloadEditFieldLabel.HorizontalAlignment = 'right';
            app.TotalPayloadEditFieldLabel.Position = [50 27 269 22];
            app.TotalPayloadEditFieldLabel.Text = 'Total Weight Range of the Payload in the System';

            % Create TotalPayloadEditField
            app.TotalPayloadEditField = uieditfield(app.RobotArmkAnalyserUIFigure, 'numeric');
            app.TotalPayloadEditField.ValueDisplayFormat = '%10.4g';
            app.TotalPayloadEditField.Editable = 'off';
            app.TotalPayloadEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TotalPayloadEditField.Position = [334 27 68 22];

            % Create InitialWeightEditFieldLabel
            app.InitialWeightEditFieldLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.InitialWeightEditFieldLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.InitialWeightEditFieldLabel.HorizontalAlignment = 'right';
            app.InitialWeightEditFieldLabel.Position = [407 27 98 22];
            app.InitialWeightEditFieldLabel.Text = '+ Initial Weight of';

            % Create InitialWeightEditField
            app.InitialWeightEditField = uieditfield(app.RobotArmkAnalyserUIFigure, 'numeric');
            app.InitialWeightEditField.ValueDisplayFormat = '%10.4g';
            app.InitialWeightEditField.Editable = 'off';
            app.InitialWeightEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.InitialWeightEditField.Position = [520 27 68 22];

            % Create kgLabel
            app.kgLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.kgLabel.Position = [595 58 25 22];
            app.kgLabel.Text = 'kg';

            % Create kgLabel_2
            app.kgLabel_2 = uilabel(app.RobotArmkAnalyserUIFigure);
            app.kgLabel_2.Position = [595 27 25 22];
            app.kgLabel_2.Text = 'kg';

            % Create NmLabel
            app.NmLabel = uilabel(app.RobotArmkAnalyserUIFigure);
            app.NmLabel.Position = [595 89 28 22];
            app.NmLabel.Text = 'N/m';

            % Show the figure after all components are created
            app.RobotArmkAnalyserUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = kAnalyser

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.RobotArmkAnalyserUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.RobotArmkAnalyserUIFigure)
        end
    end
end