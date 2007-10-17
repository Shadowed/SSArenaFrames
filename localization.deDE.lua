if( GetLocale() ~= "deDE" ) then
	return;
end

SSAFLocals = setmetatable( {
}, { __index = SSAFLocals } );