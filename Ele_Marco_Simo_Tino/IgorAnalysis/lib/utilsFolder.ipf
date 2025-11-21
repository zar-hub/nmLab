function copyToFolder(string path, string name)
	wave w = $name
	if(!waveexists(w))
		print "Error, wave %s not found\n", name
	endif
	duplicate/o $name, $(path + ":" + name)
end


function/s moveToFolder(string path, string name)
	copyToFolder(path, name)
	killwaves/z $name 
	return path + ":" + name
end
