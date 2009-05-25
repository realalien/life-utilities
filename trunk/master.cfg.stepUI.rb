
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
		@cbx_map_step = []
	end
end

class BuildbotFrame < Frame
	def initialize
		super(nil,
			  :title => "Steps For Build Master",
			  :pos => [150, 150],
			  :size => [ 400, 300 ]
			 )
        @main_sizer = BoxSizer.new(VERTICAL)
        self.set_sizer(@main_sizer)		
	# --------------   upper panel  -----------------------
	@panel = Panel.new(self)
	@main_sizer.add(@panel, 1 , Wx::GROW|Wx::TOP, 1  , nil )

#	file_loc_lbl = StaticText(panel, -1, "master.cfg location:", 
#							  DEFAULT_POSITION, DEFAULT_SIZE, ALIGN_CENTER) 
        @file_loc_txt = TextCtrl.new(@panel, -1)
	@file_chooser_btn = Button.new(@panel,
								 -1,
								 "Choose a master.cfg")
    @upper_sizer = BoxSizer.new(HORIZONTAL)
	@panel.set_sizer(@upper_sizer)
	@upper_sizer.add(@file_loc_txt, 0, GROW|EXPAND, 1 , nil)
    @upper_sizer.add(@file_chooser_btn, 0, GROW|EXPAND, 1 , nil)
	# -------------   middle checkboxes panel --------------
	# the panel holding all the checkboxes(addStep line of cfg)
	@mid_panel = Panel.new(self)
    @main_sizer.add(@mid_panel, 5 , Wx::GROW|Wx::EXPAND, 5 , nil )
 
   @demo_text = TextCtrl.new(@mid_panel, -1, "anchored in middle panel" )
						 # DEFAULT_POSITION, DEFAULT_SIZE, 3 )	 

    @mid_sizer = BoxSizer.new(VERTICAL)
	@mid_panel.set_sizer(@mid_sizer)

   # @mid_sizer.add(@demo_text, 1 , Wx::GROW|Wx::EXPAND, 1 , nil )
	# ======    testing section  ============
	@boxes = []
	(1..5).each do | i |
	#	step_cbx = CheckBox.new(@mid_panel, i, "Step No."+i.to_s)
	#	@boxes << step_cbx   
	end

    #@boxes.each do | step |
	#	@mid_sizer.add(step , 1, GROW , 1, nil)
	#end

	# ======================================

	# -------------   bottom panel  -------------
	@bottom_panel = Panel.new(self)
	@main_sizer.add(@bottom_panel, 1 , Wx::GROW|Wx::BOTTOM, 5 , nil )
    
	@preview_change_btn = Button.new(@bottom_panel, -1, "Preview changes")
	@apply_change_btn = Button.new(@bottom_panel,
								   -1 , 
								   "Apply change!")

	@bottom_panel.set_sizer(@bottom_sizer)
	@bottom_sizer = BoxSizer.new(HORIZONTAL)
	@upper_sizer.add(@preview_change_btn, 0, GROW|EXPAND, 1 , nil)
    @upper_sizer.add(@apply_change_btn, 0, GROW|EXPAND, 1 , nil)
	evt_button(@file_chooser_btn.get_id()) { |event| read_cfg(event) }


	end

	# read the master.cfg file and produce controls related
	def read_cfg(event)
		fd = FileDialog.new(nil)
		fd.show_modal
		path = fd.get_path  # included the filename
		# filename = fd.get_filename
		@file_loc_txt.write_text(path)
		@steps = load_steps_from_master_cfg(path) # TODO: info (line_num, step name, on/off status)
		# =====   inspect section  =====
		str = ""
		@steps.each do |step|
			str += "#{step.name} , #{step.status}\n"
		end
		@file_loc_txt.write_text(str)
		# ==============================
		@steps.each do | step |
			# TODO: shall I maintain the status in memory?
			step_cbx = CheckBox.new(@mid_panel, -1 , "Step "+ step.name)
		    evt_checbox(step_cbx.get_id) { | event | maintain_map(event) }
			@cbx_map_step.store(step_cbx , step)
			step_cbx.set_value(false) if step.status == false
			step_cbx.set_value(true) if step.status == true
			@boxes << step_cbx
		end	

		# paint on graphic
		@boxes.each do | step_cbx |
			@mid_sizer.add(step_cbx, 1, GROW , 1, nil)
		end

		# produce collections of checkboxes,  TODO,  is there MVC code, javabean protocal I can follow?
		
	end

	def write_cfg(event)
			
	end

	# SUG: http://wxruby.rubyforge.org/doc/eventhandlingoverview.html
	def maintain_map(event)
		if @cbx_map_step.size == 0
			MessageDialog.new(nil, "no cbx => step mapping found!", 
			return
		end

		if 
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

# experiment, test if we can add non-graphic properties, maybe it's not good choice, some layers of code may be better.
#class CustomizedCheckbox < Checkbox
		
#end

class BuildbotStepsQuickSwitch < App
	def on_init
		BuildbotFrame.new.show
	end

end

BuildbotStepsQuickSwitch.new.main_loop
