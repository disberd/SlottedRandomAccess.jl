"""
    LogUniform_dB(min_db,max_db)
Defines a distribution whose pdf is uniform in dB between `min_db` and `max_db`.
"""
function LogUniform_dB(min_db,max_db)
	a = 10^(min_db/10)
	b = 10^(max_db/10)
	LogUniform(a,b)
end