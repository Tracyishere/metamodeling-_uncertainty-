% Make a DBN for the postprandial model with the following variables
%
% Time-dependent variables
%
% Coupling variables
% G.C, Gcell.C, Spa.C
%
% Observed variables
%
% Time-invariant variables
%
% Parameters
%
% To generate a conditional gaussian model

function [dbn_factory]= make_postprandial_dbn(DGd_mean_postprandial, DGd_cov_postprandial, Gb_mean_postprandial,...
                                              Gb_cov_postprandial, G_mean_postprandial, G_cov_postprandial,...
                                              DG_mean_postprandial, DG_cov_postprandial, Y_mean_postprandial,...
                                              Y_cov_postprandial, S_mean_postprandial, S_cov_postprandial,...
                                              I_mean_postprandial, I_cov_postprandial, Sb_mean_postprandial,...
                                              Sb_cov_postprandial, alpha_postprandial, beta_postprandial,...
                                              gamma_postprandial, k1_postprandial,k2_postprandial,...
                                              k3_postprandial, k4_postprandial, K_postprandial,...
                                              dt_postprandial, cov_scale_postprandial, ...
                                              G_c_weight, G_pr_weight, G_obs_weight, G_cell_obs_weight,...
                                              G_pl_obs_mean, G_pl_obs_cov, G_cell_obs_mean, G_cell_obs_cov);
    
    node_names = {'DGd.postprandial','DGd.C','DGd.obs','G.postprandial','G.C',...
                  'Gcell.C','Gb.postprandial','DG.postprandial','Y.postprandial','Spa.C',...
                  'Sb.postprandial','S.postprandial','I.postprandial','Gcell.obs','G.obs','Gpr.obs'}; 
    
    n= length(node_names);
    
    % Intra - in one time slice
    edges_intra= {'DGd.postprandial','DGd.C';'DGd.C','DGd.obs';'Gb.postprandial','DG.postprandial';...
                  'G.postprandial','DG.postprandial'; 'G.postprandial', 'G.C';'G.C','Gcell.C';...
                  'DGd.postprandial','S.postprandial'; ...
                  'Gcell.obs','Gcell.C'; 'G.obs', 'G.C';'G.postprandial','Gpr.obs';...
                  'Y.postprandial','S.postprandial';'Spa.C','S.postprandial';'Sb.postprandial','S.postprandial'};


%     node_names = {'DGd.postprandial','DGd.C','DGd.obs','G.postprandial','G.C',...
%                   'Gcell.C','Gb.postprandial','DG.postprandial','Y.postprandial','Spa.C',...
%                   'Sb.postprandial','S.postprandial','I.postprandial'}; 
%     n= length(node_names);
%     
%     % Intra - in one time slice
%     edges_intra= {'DGd.postprandial','DGd.C';'DGd.C','DGd.obs';'Gb.postprandial','DG.postprandial';...
%                   'G.postprandial','DG.postprandial'; 'G.postprandial', 'G.C';'G.C','Gcell.C';...
%                   'DGd.postprandial','S.postprandial'; ...
%                   'Y.postprandial','S.postprandial';'Spa.C','S.postprandial';'Sb.postprandial','S.postprandial'};
%     
    % Inter - between time slices
    edges_inter= { 'DGd.postprandial','DGd.postprandial';'DGd.postprandial','G.postprandial';'I.postprandial','G.postprandial';...
                   'G.postprandial', 'G.postprandial'; 'Gb.postprandial','Gb.postprandial';...
                   'DG.postprandial','G.postprandial'; 'DG.postprandial','DG.postprandial'; ...
                   'DG.postprandial','Y.postprandial';'Y.postprandial', 'Y.postprandial'; 'S.postprandial','S.postprandial';...
                   'S.postprandial','I.postprandial';'I.postprandial','I.postprandial' }; 
    
    % 'Equivalence classes' specify how the template is initiated and rolled
    % Specify which CPD is associates with each node in either time
    % slice 1 (eclass1) or in slice 2 onwards (eclass2)
    eclass1_map= containers.Map();
    eclass2_map= containers.Map();
    for i=1:numel(node_names)
        node_name= node_names{i};
        cpd_name= [ node_name '.intra' ];
        eclass1_map(node_name) = cpd_name;
        eclass2_map(node_name) = cpd_name; 
    end
    eclass2_map('DGd.postprandial')= 'DGd.postprandial.inter';
    eclass2_map('Gb.postprandial')= 'Gb.postprandial.inter';
    eclass2_map('G.postprandial')= 'G.postprandial.inter';
    eclass2_map('DG.postprandial')= 'DG.postprandial.inter';
    eclass2_map('Y.postprandial')= 'Y.postprandial.inter';   
    eclass2_map('S.postprandial')= 'S.postprandial.inter';   
    eclass2_map('I.postprandial')= 'I.postprandial.inter';  
    
    % elcass1 (time-slice 0 or all parents are in the same time slice)
    % When using clamp, the root node is clamped to the N(0,I) distribution, so that we will not update these parameters during learninG. 
    CPDFactories= {};
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'DGd.postprandial', 0, ...
        {'mean', DGd_mean_postprandial,   'cov', DGd_cov_postprandial} ); % DGd
    
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'DGd.C', 0, ...
        {'mean', 0.0,   'cov', DGd_cov_postprandial*cov_scale_postprandial, 'weights', 1.0} ); % DGd.C = 1.0 * DGd
    
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'DGd.obs', 0, ...
        {'mean', 0.0,   'cov', DGd_cov_postprandial*cov_scale_postprandial, 'weights', 1.0} ); % DGd.obs = 1.0 * DGd.C

    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'Gpr.obs', 0, ...
        {'mean', 0.0,   'cov', Gb_cov_postprandial, 'weights', 1.0} ); % DGd.obs = 1.0 * DGd.C
    
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'Gb.postprandial', 0, ...
        {'mean', Gb_mean_postprandial,   'cov', Gb_cov_postprandial} ); % Gb
    
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'G.postprandial', 0, ...
        {'mean', G_mean_postprandial, 'cov', G_cov_postprandial} ); % G 
    
    weights_G_minus_h0_map_T0= containers.Map(); % parents in slice t
    weights_G_minus_h0_map_T1= containers.Map(); % parents in slice t+1
    weights_G_minus_h0_map_T0('G.postprandial')= 1.0;
    weights_G_minus_h0_map_T0('Gb.postprandial')= -1.0;
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'DG.postprandial', 0, ...
        {'mean', DG_mean_postprandial, 'cov', DG_cov_postprandial*cov_scale_postprandial}, ...
        weights_G_minus_h0_map_T0, weights_G_minus_h0_map_T1); % DG = 1.0 * G - 1.0 * Gb
    
%     CPDFactories{end+1} = ...
%         CPDFactory('Gaussian_CPD', 'G.C', 0,   ...
%         {'mean', 0.0, 'cov',  G_cov_postprandial*cov_scale_postprandial, 'weights', 1.0} ); % G.C = 1.0 * G
        
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'G.C', 0,   ...
        {'mean', 0.0, 'cov',  G_cov_postprandial*cov_scale_postprandial, 'weights', [G_pr_weight, G_obs_weight]} ); % G.C = 1.0 * G
      
%      CPDFactories{end+1} = ...
%         CPDFactory('Gaussian_CPD', 'G.C', 0,   ...
%         {'mean', 0.0, 'cov',  G_pl_cov, 'weights', [G_pr_weight, G_obs_weight]} ); % G.C = 1.0 * G

    CPDFactories{end+1} = ...
       CPDFactory('Gaussian_CPD', 'G.obs', 0, ...
       {'mean', G_pl_obs_mean, 'cov', G_pl_obs_cov}); 
     
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'Gcell.C', 0, ...
        {'mean', 0.0,'cov',  G_cov_postprandial*cov_scale_postprandial, 'weights', [G_c_weight, G_cell_obs_weight]}); % G.obs = 0.5 * G.C
    
%     CPDFactories{end+1} = ...
%             CPDFactory('Gaussian_CPD', 'Gcell.C', 0, ...
%             {'mean', 0.0,'cov',  G_cov_postprandial*cov_scale_postprandial, 'weights', 0.5});
    
    CPDFactories{end+1} = ...
       CPDFactory('Gaussian_CPD', 'Gcell.obs', 0, ...
       {'mean', G_cell_obs_mean, 'cov',  G_cell_obs_cov}); 
    
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'Y.postprandial', 0, ...
        {'mean', Y_mean_postprandial, 'cov', Y_cov_postprandial} ); % Y
    
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'Sb.postprandial', 0, ...
        {'mean', Sb_mean_postprandial, 'cov', Sb_cov_postprandial} ); ...

    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'Spa.C', 0, ...
        {'mean', Sb_mean_postprandial, 'cov', Sb_cov_postprandial} ); % Sb
    
    weights_S0_map_T0= containers.Map(); % parents in slice t
    weights_S0_map_T1= containers.Map(); % parents in slice t+1
    INITIAL_K = K_postprandial;
    weights_S0_map_T0('DGd.postprandial')= 0.0;
    weights_S0_map_T0('Spa.C')= 0.0;
    weights_S0_map_T0('Sb.postprandial')= 1.0;
    weights_S0_map_T0('Y.postprandial')= 0.0;
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'S.postprandial', 0, ...
        {'mean', 0.0, 'cov', Sb_cov_postprandial*cov_scale_postprandial}, ...
        weights_S0_map_T0, weights_S0_map_T1); % S = 1.0 * Sb
    
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'I.postprandial', 0, ...
        { 'mean', I_mean_postprandial,'cov', I_cov_postprandial} ); % I
 
    % eclass2 (time-slice t+1 with parents in the previous time slice)
    CPDFactories{end+1} = ...
       CPDFactory('Gaussian_CPD', 'DGd.postprandial', 1, ...
        {'mean',DGd_mean_postprandial,'cov', DGd_cov_postprandial, 'weights', 0.0} ); % Gcelltake(t+1) = 0.0 * Gcelltake(t+1)
    
    CPDFactories{end+1} = ...
       CPDFactory('Gaussian_CPD', 'Gb.postprandial', 1, ...
        {'mean',0.0,'cov', Gb_cov_postprandial*cov_scale_postprandial, 'weights', 1.0} ); % Gb(t+1) = 1.0 * Gb(t)    

    weights_G1_map_T0= containers.Map(); 
    weights_G1_map_T1= containers.Map();
    INITIAL_k1= k1_postprandial;
    INITIAL_k2= k2_postprandial;
    weights_G1_map_T0('DGd.postprandial')= dt_postprandial;
    weights_G1_map_T0('I.postprandial')= -INITIAL_k1*dt_postprandial; % parents in slice t
    weights_G1_map_T0('G.postprandial')= 1.0-INITIAL_k2*dt_postprandial; % parents in slice t+1
    weights_G1_map_T0('DG.postprandial')= k3_postprandial; % parents in slice t+1
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'G.postprandial', 1, ...
        {'mean',0.0,'cov', G_cov_postprandial}, ...
        weights_G1_map_T0, weights_G1_map_T1); % G (t+1) = 1.0 * G(t) + 1.0 * DGd(t+1) - INITIAL_k1 * dt_postprandial * I(t) - INITIAL_k2 * dt_postprandial * G(t)

    weights_G_minus_h1_map_T0= containers.Map();
    weights_G_minus_h1_map_T1= containers.Map();
    weights_G_minus_h1_map_T0('DG.postprandial')= 0.0;
    weights_G_minus_h1_map_T1('G.postprandial')= 1.0;
    weights_G_minus_h1_map_T1('Gb.postprandial')= -1.0;
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'DG.postprandial', 1, ...
        {'mean', 0.0, 'cov', G_cov_postprandial*cov_scale_postprandial}, ...
        weights_G_minus_h1_map_T0, weights_G_minus_h1_map_T1); % DG(t+1) = 1.0 * G(t+1) - 1.0 * Gb(t+1)
    
    weights_Y1_map_T0= containers.Map();
    weights_Y1_map_T1= containers.Map();
    INITIAL_ALPHA= alpha_postprandial;
    INITIAL_BETA= beta_postprandial;
    weights_Y1_map_T0('Y.postprandial')= 1.0 - dt_postprandial * INITIAL_ALPHA;
    weights_Y1_map_T0('DG.postprandial')= dt_postprandial* INITIAL_ALPHA * INITIAL_BETA;
    CPDFactories{end+1} = ...
        CPDFactory('Gaussian_CPD', 'Y.postprandial', 1, ...
        {'mean',0.0,'cov', Y_cov_postprandial*cov_scale_postprandial}, ...
        weights_Y1_map_T0, weights_Y1_map_T1); % Y(t+1) = (1.0 - dt_postprandial * INITIAL_ALPHA) * Y(t) + (dt_postprandial* INITIAL_ALPHA * INITIAL_BETA) * DG
    
    weights_S1_map_T0= containers.Map();
    weights_S1_map_T1= containers.Map();
    weights_S1_map_T1('DGd.postprandial')= K_postprandial;
    weights_S1_map_T1('Sb.postprandial')= 1.0;
    weights_S1_map_T1('Spa.C')= 0.0;
    weights_S1_map_T1('Y.postprandial')= 1.0;
    weights_S1_map_T0('S.postprandial')= 0.0;
    CPDFactories{end+1}=  ...
        CPDFactory('Gaussian_CPD', 'S.postprandial', 1, ...
        {'mean', 0.0, 'cov', Sb_cov_postprandial*cov_scale_postprandial}, ...
        weights_S1_map_T0, weights_S1_map_T1); % S(t+1) = Sb_mean_postprandial + 0.0 * S(t) + INITIAL_K * DG(t+1) + 1.0 * Sb(t+1) + 1.0 * Y(t+1)
    
    weights_I1_map_T0= containers.Map(); 
    weights_I1_map_T1= containers.Map(); 
    INITIAL_GAMMA= gamma_postprandial;
    weights_I1_map_T0('I.postprandial')= 1 - INITIAL_GAMMA*dt_postprandial;
    weights_I1_map_T0('S.postprandial')= k4_postprandial*dt_postprandial; % fast
    CPDFactories{end+1}= ...
        CPDFactory('Gaussian_CPD', 'I.postprandial', 1, ...
        {'mean', 0.0, 'cov', I_cov_postprandial*cov_scale_postprandial}, ...
        weights_I1_map_T0, weights_I1_map_T1); % I(t+1) = (1 - INITIAL_GAMMA*dt_postprandial) * I(t) + dt_postprandial * S(t)
    
    % Final DBN factory
    dbn_factory= DBNFactory( ...
        node_names, edges_intra, edges_inter, ...
        eclass1_map, eclass2_map, CPDFactories);
end