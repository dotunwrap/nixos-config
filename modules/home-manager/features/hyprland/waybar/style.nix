{ ... }:

{
  programs.waybar.style = ''
    * {
      border: none;
    }
    
    #waybar {
      background-color: alpha(@base, 0.7);
      border-bottom: solid alpha(@surface1, 0.7) 2;
    }
    
    #user {
      padding-left: 10;
    }
    
    #language {
      padding-left: 15;
    }
    
    #keyboard-state label.locked {
      color: @yellow;
    }
    
    #workspaces {
      margin-left: 10;
    }
    
    #workspaces button {
      color: @text;
      font-size: 1.25rem;
    }
    
    #workspaces button.empty {
      color: @overlay0;
    }
    
    #workspaces button.active {
      color: @peach;
    }
    
    #submap {
      background-color: alpha(@surface1, 0.7);
      border-radius: 15;
      padding-left: 15;
      padding-right: 15;
      margin-left: 20;
      margin-right: 20;
      margin-top: 5;
      margin-bottom: 5;
    }
    
    window.top_bar .modules-center {
      font-weight: bold;
      background-color: alpha(@surface1, 0.7);
      color: @peach;
      border-radius: 15;
      padding-left: 20;
      padding-right: 20;
      margin-top: 5;
      margin-bottom: 5;
    }
    
    #custom-separator {
      color: @green;
    }
    
    #custom-separator_dot {
      color: @green;
    }
    
    #clock.time {
      color: @flamingo;
    }
    
    #clock.week {
      color: @sapphire;
    }
    
    #clock.month {
      color: @sapphire;
    }
    
    #clock.calendar {
      color: @mauve;
    }
  '';
}
