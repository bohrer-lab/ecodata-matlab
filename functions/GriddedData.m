classdef GriddedData < handle
    properties 
        filename
        latvar
        lonvar
        timevar
        var_of_interest
        cmap
        invert_cmap
        cbar_limits
        show_colorbar
        time_index
    end

    methods

        function obj = GriddedData(filein, kwargs)
            % Constructor
            arguments
                filein
                kwargs.latvar = ''
                kwargs.lonvar = ''
                kwargs.timevar = ''
                kwargs.var_of_interest = ''
                kwargs.cmap  = ''
                kwargs.invert_cmap = false
                kwargs.cbar_limits = []
                kwargs.show_colorbar = true
            end

            if nargin > 0
                obj.filename = filein;
                obj.latvar = kwargs.latvar;
                obj.lonvar = kwargs.lonvar;
                obj.timevar = kwargs.timevar;
                obj.var_of_interest = kwargs.var_of_interest;
                obj.cmap = kwargs.cmap;
                obj.invert_cmap = kwargs.invert_cmap;
                obj.cbar_limits = kwargs.cbar_limits;
                obj.show_colorbar = kwargs.show_colorbar;

                obj.time_index = read_nc_timestamps(filein, kwargs.timevar);
            end
        end
    end
end

