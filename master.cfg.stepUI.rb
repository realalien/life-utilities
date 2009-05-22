
# Purpose: read steps in master.cfg to be used in a gui tool, 
#  with little fuss with commenting or uncommenting the steps
#  when testing them out.

require 'wx'

include Wx



class StepStatus
	attr_accessor :line_num, :name, :status

	def initialize(no, name, status)
		self.line_num  = no
		self.name = name 
		self.status = status
	end
end

class BuildbotFrame < Frame
	def initialize
		super(nil,
			  :title => "Steps For Build Master",
			  :pos => [150, 150],
			  :size => [ 300, 200 ]
			 )
		
	@panel = Panel.new(self)

#	file_loc_lbl = StaticText(panel, -1, "master.cfg location:", 
#							  DEFAULT_POSITION, DEFAULT_SIZE, ALIGN_CENTER) 
    @file_loc_txt = TextCtrl.new(@panel, -1)
	@file_chooser_btn = Button.new(@panel,
								 id => -1,
								 label => "Choose a master.cfg")

	@apply_change_btn = Button.new(@panel,
								  id => -1 , 
								  label => "Apply change!")

	evt_button(@file_chooser_btn.get_id()) { |event| read_cfg(event) }

#	@panel_cbx = Panel.new(self) # holding all the checkboxes(addStep line of cfg)
	end

	def read_cfg(event)
		fd = FileDialog.new(nil)
		fd.show_modal
		path = fd.get_path  # included the filename
		# filename = fd.get_filename
		@file_loc_txt.write_text(path)
		@steps = load_steps_from_master_cfg(path) # TODO: info (line_num, step name, on/off status)
		str = ""
		@steps.each do |step|
			str += "#{step.name} , #{step.status}\n"
		end
		@file_loc_txt.write_text(str)
	end

	def write_cfg(event)
			
	end

	def load_steps_from_master_cfg(file)
		steps = []
		modified = []
		step_line = 0
		if File.exists?(file)
			f = File.open(file, "r")
			lines = f.readlines
			lines.each do | line |
				if line =~ /.*addStep\((.*)\)/
					step_line += 1
					name = $1 
					status = false
					if line.strip =~ /^#/  # commented addStep
						status = false
					else
						status = true
					end
				    steps << StepStatus.new("11", name, status)
				end
			end
		    f.close	
		end
#		steps.each do |step|
#			str = ""
#			str += "#{step.name} , #{step.status}\n"
#			@file_loc_txt.write_text(str)
#		end
		return  steps 
	end
end


class BuildbotStepsQuickSwitch < App
	def on_init
		BuildbotFrame.new.show
	end

end

BuildbotStepsQuickSwitch.new.main_loop
