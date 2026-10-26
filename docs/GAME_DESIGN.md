# 🎭 Echoes of the Backstage

> **Genre:** Tactical Co-op Sound-Based Horror  
> **Target Audience:** 1-4 Players (Co-op / Multiplayer)  
> **Core Hook:** You cannot see the monster with your eyes—you can only track it with your ears. Silence is your only armor.

---

## 1. High Concept & Core Gameplay Loop

Set in the vast, decaying backstages and labyrinthine corridors of a massive opera house, players must navigate through near-pitch darkness to repair the theatre's main power grid and escape. 

Unlike traditional horror games that rely on visual jumpscares, **Echoes of the Backstage** flips the paradigm:
* **The Entity is completely invisible.**
* **3D Positional Audio (HRTF) is mandatory:** You locate the threat strictly by sound—heavy footsteps, hollow breathing, or the creak of floorboards.
* **Sound goes both ways:** Every action you take—walking, talking on proximity voice chat, dropping an item, or interactable noise traps—alerts the entity to your exact coordinates.

---

## 2. Core Mechanics

### 🔊 Sound & Noise Detection System
* **Stance-Based Movement:**
  * **Crouch Walking:** Silent, but slow.
  * **Standard Walking:** Generates low-frequency noise (audible to nearby entities).
  * **Sprinting:** Emits high-volume sound waves that immediately draw the entity from a distance.
* **Microphone / Voice Integration:**
  * The game actively monitors player microphone volume (or proximity chat). Loud real-world reactions, coughing, or panicked calls will ping your position directly to the entity.
  * **Walkie-Talkies:** Allow long-distance communication across the map, but generate a sharp static burst (*krr-chk*) whenever the button is pressed, which can easily betray your location if the creature is lurking nearby.

### 🎧 Spatial Echolocation & Visualization Tools
* **Physical Noise Distractions:** Throwable items like stage props, glass bottles, or wind-up music boxes can be thrown to distract the entity or map out room geometry through reverberation.
* **Decibel Meters / Audio Sensors:** Specialized gear found in tech rooms that displays visual sound-level spikes, indicating how close the entity is even when it is standing completely still.
* **Subtle Audio Ripples:** Brief, wave-like distortion effects ripple across the floor when the creature makes sudden, heavy contact with the environment.

### 🎭 Dynamic Environmental Hazards ("Sound Traps")
* **Creaky Stageboards:** Wooden floorboards that squeak when walked on unless stepped over carefully.
* **Scattered Stage Props:** Tipping over violin cases, walking through shattered glass, or brushing past heavy velvet curtains produces distinct noise signatures.
* **Ventilation & Stage Machinery:** Periodically, noisy HVAC systems or stage elevators activate, creating temporary "noise cover" that allows players to sprint—but also deafens them to the entity’s footsteps.

---

## 3. Monster Design: *The Stagehand / The Echo*

The AI operates strictly on spatial acoustic logic:

| State | Behavior |
| :--- | :--- |
| **1. Patrol** | Roams backstage corridors at a slow pace, generating deep, hollow footfalls and subtle breathing effects in 3D space. |
| **2. Investigate** | Upon detecting a sound (dropped item, sprint step, voice spike), it stops, turns toward the noise source, and emits a high-frequency chirp to sonar-map the room. |
| **3. Hunt** | Triggers when noise crosses a critical decibel threshold nearby. The entity rushes the sound origin at high speed. |
| **4. Mimicry (Special Ability)** | The entity can replay distorted audio fragments of player voices or footsteps to lure unsuspecting teammates out of hiding spots. |

---

## 4. Map & Environmental Aesthetics

* **Setting:** 1920s Grand Opera House (Backstage, Wardrobe Rooms, Catwalks, Orchestra Pit, Dressing Rooms, and Sub-basement Mechanical Vaults).
* **Lighting Strategy:** Low ambient light with volumetric fog and moody point lights (flickering emergency signs, stage spotlights). Flashlights light up the environment, but illumination does **not** draw the creature—only sound does.

---

## 5. Why It Works on Roblox

1. **High Viral / Content Potential:** Real-time microphone detection creates hilarious, unpredictable streaming moments when a player accidentally gasps, sneezes, or drops a prop.
2. **Atmospheric Tension Over Cheap Jumpscares:** The dread builds organically as players crouch together in complete silence while heavy footsteps pass inches away in the dark.
3. **High Replay Value:** Procedural item placement, randomized sound traps, and dynamic AI paths ensure no two escape attempts feel identical.
