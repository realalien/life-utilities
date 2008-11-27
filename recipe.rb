

class Recipe
	
	attr_accessor :main_materials, :sub_materials , :sauces
				# 主料，辅料，调料
	
	attr_accessor :steps      #制作过程（刀工和烹制）

	attr_accessor :measures   #要点分析

	attr_accessor :standards  #质量标准
	


end

my = Recipe.new
my.main_materials = ["猪腿肉"]
my.sub_materials = ["银芽"]
my.sauces = ["鸡蛋清","精盐","味精","料酒","生粉"]
my.steps = ["1. todo", "2. todo2", "3. todo3" ]
my.measures = ["good taste"]
my.standards = []


# check the inventory to find
# * recipes that all resources are available
# * calculate the time including preparation, and cooking
# * calculate nutrition and advice
# * make a composition advice of several cookings
# * make a advice depends on eater's mood, wheather, season, or other context.
#
class RecipeAdvisor

def gen_a_recipe
	# do the Recipes and Inventory checking
	if RecipesManager.collect.size <= 0
		raise "No recipe available, please add recipe through 'RecipesManager'"
	end	
	
	if Inventory.collect.size <= 0 
		raise "No item in the inventory, please buy some food and register on Inventory"
	end

	# TODO: search through inventory is time consuming and inefficient when it grows with hundreds of items, how do I find a way to get a recipe ready for cooking?
	# TODO: remove the mock recipe
	my = Recipe.new
	my.main_materials = ["猪腿肉"]
	my.sub_materials = ["银芽"]
	my.sauces = ["鸡蛋清","精盐","味精","料酒","生粉"]
	my.steps = ["1. todo", "2. todo2", "3. todo3" ]
	my.measures = ["good taste"]
	my.standards = []
	return my			
end


end
