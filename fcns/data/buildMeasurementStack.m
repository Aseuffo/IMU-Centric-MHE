function [y_measurements, measurementNames] = buildMeasurementStack( ...
    vx_meas, r_meas, ay_meas, Fyf_meas, Fyr_meas, flags)

    if flags.ay_in_cost == true || flags.ay_in_state == true

        y_measurements = [vx_meas, r_meas, ay_meas];
        measurementNames = {'vx', 'r', 'ay'};

    elseif flags.split_forces == true

        y_measurements = [vx_meas, r_meas, Fyf_meas, Fyr_meas];
        measurementNames = {'vx', 'r', 'Fyf', 'Fyr'};

    else

        y_measurements = [vx_meas, r_meas];
        measurementNames = {'vx', 'r'};

    end

end