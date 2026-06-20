extends Node

const init_state = preload("uid://cwkh6rk77ggh2")
const move_cost = preload("uid://0h6yv17aksse")
const effect_duration = preload("uid://dnx36iun4gt5p")
const item_slot = preload("uid://bragr3ytwxyik")
const trick_question_decision := preload("uid://dl4njbrtd7u0t")
const name_container := preload("uid://byokucabugjo")
const shadow_text_settings := preload("uid://yde7hyop4yq4")
const wheel_item_label := preload("uid://b2c2jyon6rsdp")
const fortune_wheel_shader := preload("uid://wryidgesclld")
const moving_arrows_shader := preload("uid://dqijec0icxeev")
var restaurant_minigame := load("uid://dci365yxq04no")
const conveyor_arrow_left := preload("uid://lsic0kxyf3v7")
const conveyor_arrow_right := preload("uid://mlvx0iysm1dy")
const falling_ingredient_scene := preload("uid://dpat2hkit0sx0")
const falling_ingredient_shader := preload("uid://bsu0basrbuots")
const player_ingredient_scene := preload("uid://gi430yjahyj2")
const ingredient_collider_scene := preload("uid://cuoijvayuffan")
const restaurant_item_slot := preload("uid://srs2g7wicd1q")
var conveyor_ingredient := load("uid://b61nq8eg3e463")
const barrel_scene := preload("uid://l637mc00fqyq")
const dropped_ingredient := preload("uid://duum2avyhh1o")
const restaurant_chair_scene := preload("uid://c25vd5istxvob")
const customer_scene := preload("uid://csxq2bh054253")
const customer_food_scene := preload("uid://drie3qituxqft")
const score_notice_scene := preload("uid://c1uplv0ax4wmg")
const score_milestone_scene := preload("uid://c3bj8c75p3ikl")
const food_station_scene := preload("uid://u5jm4evd6o0j")
const checkmark_uid = "uid://dnhuyu2114nfn"
const timer_clock_uid = "uid://bi2k7iq18pxnx"
const food_spritesheet_uid = "uid://ccvqa2ejeeolv"
var board_scene = load("uid://bq8uq3y6war4f")
const question_scene = preload("uid://bmpo8accv5c6")
const question_ingredient_scene := preload("uid://cl6fwuolftma6")
const question_button := preload("uid://b7itb1gmis7pn")
const question_clock := preload("uid://bysq3yjn877od")
const title_screen_scene := preload("uid://bpgi4bffsy83i")

var food_recipes : Dictionary[Ingredient.FoodType, RestaurantRecipe] = {
	Ingredient.FoodType.Currywurst: load("uid://bqk6h6qfe50t1"),
	Ingredient.FoodType.FriedCheese: load("uid://bpy5optx37bee"),
	Ingredient.FoodType.Grostl: load("uid://dyi17tloq5nvv"),
	Ingredient.FoodType.Kasespatzle: load("uid://ctgtpeyre3y77"),
	Ingredient.FoodType.Schnitzel: load("uid://cxunov1l8rl5n")
}

const power_up_sfx := preload("uid://bpvqwvp3oei2q")
const button_clicked_sfx := preload("uid://vc0ficlfwkxk")
const task_success_sfx := preload("uid://dadnawol3qnog")
const task_failure_sfx := preload("uid://by1jlkv6u6w8l")

const board_music := preload("uid://27wodk4ei5rl")
const restaurant_music := preload("uid://duu7222knu0pl")
const quiz_music := preload("uid://b8dmhbhel5d6d")

const question_subscene_dict : Dictionary[Question.QuestionType, PackedScene] = {
	Question.QuestionType.IngredientQuestion: preload("uid://646kf0uhtr74"),
	Question.QuestionType.ClockQuestion: preload("uid://cmsvbby1xq7q8"),
	Question.QuestionType.FamilyTree: preload("uid://cudeoiwyyn40c")
}

const tutorial_state := preload("uid://b5nlnubo2etxf")
const family_member := preload("uid://wn1m8bmf11se")
