# First person template (Godot)
This is a template for first person games made in godot, originally i'd use it on a game but i no longer wanted to develop it so i decided
to leave this public for everyone to see.



https://github.com/user-attachments/assets/f4eba467-1130-4ff6-9d8b-0f5be210b9d0




# Content:
- Smooth movement, crouching, looking around.
- Camera bobbing
- Fall impact animations
  - Light impact: When the player falls from a not-so-high place the camera stumbles a little - Enabled after 2 seconds of air time
  - Impact: When the player falls from a high place the player's control are disabled and an animation of impact is played - Enabled after 3 seconds of airtime
  - Both of those plays an "aiaiai" sound - This is a joke a friend told me to put there, feel free to replace it.
- A movement guide text - Informing how to move, crouch, sprint.
- Basic trigger system
  - Teleport: Teleport the *body* touching the trigger to an *Vector3* position - You can delay the teleport.
  - Show text: Shows an text on the bottom of the screen - There is a bunch of properties like_hold time, fade in, fade out, color.

# Disclaimer:
I am NOT an GDscript expert and the code may not be optimized, feel free to change it as you want.

## Anyway
Have fun :)


https://github.com/user-attachments/assets/01045eb5-c73c-4253-9867-716c3161f356

