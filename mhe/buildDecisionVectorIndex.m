function idx = buildDecisionVectorIndex(layout, N_MHE)

    idx = struct();

    idx.state_dim   = layout.n_states   * (N_MHE + 1);
    idx.control_dim = layout.n_controls * N_MHE;
    idx.slack_dim   = layout.n_slacks   * N_MHE;
    idx.para_dim    = layout.n_params;

    idx.state_start = 1;
    idx.state_end   = idx.state_dim;

    idx.control_start = idx.state_end + 1;
    idx.control_end   = idx.state_end + idx.control_dim;

    idx.slack_start = idx.control_end + 1;
    idx.slack_end   = idx.control_end + idx.slack_dim;

    if idx.para_dim > 0
        idx.par_start = idx.slack_end + 1;
        idx.par_end   = idx.slack_end + idx.para_dim;
    else
        idx.par_start = [];
        idx.par_end   = [];
    end

end