

# Purpose: to automize as much as work possible, customization with intelli. 
#          incl. info. collection, daily job automation, 
#          working progress auditing, notes keeping (link all the info)
#
# Idea:
# * some working style can be reused in other places, sharing the working
#   style and workflow so that life is really incremental without losing
#   experience and knowledge
#


def work_at_office
	# run programs at the startup # Win64, Vista
	progs = { 
		:deskzilla => 'C:\Program Files (x86)\Deskzilla\bin\deskzilla.exe',
        :vitualDimension => 'C:\Program Files (x86)\Virtual Dimension\VirtualDimension.exe', 
	    :outlook => 'C:\Program Files (x86)\Microsoft Office\Office12\OUTLOOK.EXE' }

	progs.values.each { | prog | puts prog+ " start to run." ;  system(prog) } 
end


if __FILE__ == $0
	work_at_office()
end
