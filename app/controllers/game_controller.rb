class GameController < ApplicationController


  def start
    if guest_user.nil?
      guest_user
    end
    @last_room = guest_user[:room_id]
  end

  def current_room
    @room = Room.find(params[:id])            #calls this room
    guest_user[:room_id] = @room[:id]         #saves room to find from main menu
    guest_user.save
    @items = Item.all                         #displays attributes for all possible items
    @inventory = guest_user[:item_id]         #allows reading of stored inventory between rooms
    @paths = @room.path                       #shortcut to this room's exits
    @action_text = @room.action_text          #WIP
    @default_room_items = @room.room_items    #set to default room state
    @room_data = {}                           #preps for use later
    if !@default_room_items.nil?             #if the room has no items skip method
      room_history
    end
    @room_data = guest_user[:room_data]
    @room_items = @room_data[@room[:id]]
    @path = []                                #declare for use
    @path_text = []                           #declare for use
    @stats = guest_user[:stats]
    @luck = guest_user[:stats][:luck]
    @paths.each_with_index do |path, index|   #puts each chance value in an array that corresponds to the path index
      if path[:chance] != nil
        luck = @luck.to_f / 100
        @chance = path[:chance] * luck
        if @chance > 100
          @chance = 100
        end
        if @chance  >= (rand(99) + 1)
          @path_text[index] = path[:text] + " (#{@chance}% chance)"
          @path[index] = path[:main_path]
        else
          @path_text[index] = path[:text] + " (#{@chance}% chance)"
          @path[index] = path[:chance_path]
        end
      else
        @path_text[index] = path[:text]
        @path[index] = path[:main_path]
      end
    end
    time_passes(params[:action_check])

    @action = [@action_text[:default]]        # Default room text
    if !@room_items.nil?                      # Room text for each default item
      @room_items.each do |item|
        if !@action_text[:pre_pickup].nil? && !@action_text[:pre_pickup][item].nil?
          @action.push(@action_text[:pre_pickup][item])
        end
      end
    end




  end

  def new_game
    guest_user[:room_data] = {}
    guest_user[:item_id] = [0]
    guest_user[:stats] = {:HP => 100, :maxHP => 100, :AP => 100, :maxAP => 100, :luck => 100}
    user = guest_user
    user.save
    redirect_to current_room_path(id: params[:id], action: true)
  end

  def continue_game
    id = guest_user[:room_id]
    redirect_to current_room_path(id: id)

  end

  def game_over
    guest_user[:room_data] = {}
    guest_user[:room_id] = nil
    guest_user[:item_id] = [0]
    guest_user[:stats] = {:HP => 100, :maxHP => 100, :AP => 100, :maxAP => 100, :luck => 100}
    user = guest_user
    user.save
    redirect_to start_menu_path
  end

  def drop                                    #Drops item from inventory into room
    @items = Item.all
    id = params[:id].to_i
    item_id = params[:item_id].to_i
    user = guest_user
    if !@items[item_id][:stats].nil?           #modifies attributes of player
      if !@items[item_id][:stats][:luck].nil?
        guest_user[:stats][:luck] -= @items[item_id][:stats][:luck]
      end
      if !@items[item_id][:stats][:maxHP].nil?
        guest_user[:stats][:maxHP] -= @items[item_id][:stats][:maxHP]
        if guest_user[:stats][:maxHP] < guest_user[:stats][:HP]
          guest_user[:stats][:HP] = guest_user[:stats][:maxHP]
        end
      end
      if !@items[item_id][:stats][:maxAP].nil?
        guest_user[:stats][:maxAP] -= @items[item_id][:stats][:maxAP]
      end
    end
    if !guest_user[:room_data][id].include? item_id
      guest_user[:item_id][guest_user[:item_id].find_index(item_id)] = nil
      guest_user[:room_data][id].push(item_id)
    end
    user.save
    redirect_to current_room_path(id: id, action_check: "action")
  end

  def pickup                                 #Takes item from room into inventory
    @items = Item.all
    id = params[:id].to_i
    item_id = params[:item_id].to_i
    user = guest_user
    if !@items[item_id][:stats].nil?           #modifies attributes of player
      if !@items[item_id][:stats][:luck].nil?
        guest_user[:stats][:luck] += @items[item_id][:stats][:luck]
      end
      if !@items[item_id][:stats][:maxHP].nil?
        guest_user[:stats][:maxHP] += @items[item_id][:stats][:maxHP]
      end
      if !@items[item_id][:stats][:maxAP].nil?
        guest_user[:stats][:maxAP] += @items[item_id][:stats][:maxAP]
      end
    end
    if !guest_user[:item_id].include? item_id
       guest_user[:item_id].push(item_id)
       debugger
       guest_user[:item_id][guest_user[:item_id].find_index(item_id)] = nil
    end
    user.save
    redirect_to current_room_path(id: params[:id], action_check: 'action')
  end

  def index                                  #Beginning of room builder GUI
    @rooms = Room.all
  end



  private

  def room_history #saves the room default items to mutate later
      if !@default_room_items.nil? && ( guest_user[:room_data].nil? || guest_user[:room_data][@room.id].nil?)
        user = guest_user
        guest_user[:room_data][@room.id] = @default_room_items
        user.save
      end
  end

  def time_passes(action = false)
    if action == 'path'
      @stats = guest_user[:stats]
      if @stats[:maxHP] > @stats[:HP]
        @stats[:HP] += 1
      end
      if @stats[:maxAP] > @stats[:AP]
        @stats[:AP] += 1
      end
      guest_user.save
    end
  end


end
