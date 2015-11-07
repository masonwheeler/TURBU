# TURBU
The TURBU project is a work in progress, an attempt to create an open-source RPG engine on par with the proprietary RPG Maker series. The project was originally being built in the Delphi language, [with a repository on Google Code,](https://code.google.com/p/turbu/) but due to various difficulties with getting good scripting support in Delphi, and the language's proprietary (and very expensive) nature creating a high barrier to entry, it's being ported to Boo.

# Goals

## Backwards compatibility
The ultimate goal of the project is to create a high-quality game engine and a corresponding designer for console-style RPGs, with a feature set that's competitive with RPG Maker.  One important part of this is backwards compatibility: the ability to import existing RPG Maker projects.  The `TURBU.RM2K.Import` assembly contains code that will successfully read existing RPG Maker 2000 and 2003 projects, which the `LCF Parser` application uses to actually import the projects to TURBU format.  The related [RMXP Scanner](https://github.com/masonwheeler/RMXP-Scanner) project contains code that can read the file format used for XP, VX, and VX Ace, laying the groundwork for future project import possibilities.

## Programmability
RPG Maker's "events" system is simple, but awkward.  It contains a small set of predefined commands that can be used, with a very limited facility for building your own commands via Common Events.  It gives you two data types to work with: one massive global array of integers, and one of boolean "switches".  None of its script routines can define parameters.  All these factors make large-scale work far more complicated than it needs to be.  XP and later add a much more capable Ruby-based scripting system, but they are two distinct things: event scrits are not Ruby scripts, and Ruby scripts can't be edited with the simple, friendly event editors.

One of the reasons the Boo language was chosen for this engine was because of its strong emphasis on *metaprogramming*: code that deals with manipulating other code.  While users will not need to learn about metaprogramming in order to use TURBU, under the hood it will provide many benefits, insluding the ability to create a much richer set of script editors, and for project developers to even design their own event functions and editor windows to work with them in a simple, user-friendly way.  TURBU will have one unified scripting system that combines the user-friendliness of event editors with the raw power of a system like RGSS.

## Ease of collaboration
Building an RPG of any serious degree of complexity requires a team.  It needs a writer, artists to create sprites, tilesets, and images, a mapmaker, a scripter, at the very least.  (Plus a composer and a SFX guy if you're really serious!)  Some people can fulfill multiple roles, but it's not very common for one person to be able to do it all.  This can get very tricky on an RPG Maker project, because its file system isn't designed for collaboration.  If the mapmaker is trying to work on a map while the scripter is writing events for it, or if two people add a new map at the same time, they won't be able to both send their work to the master copy at the same time without stomping on each other's changes.  Working around this usually involves something like a shared Dropbox folder and keeping everything in sync by sending around emails to the team telling them not to work on a certain part while you're working on it.

In the rest of the software development world, this has been a solved problem for a long time now.  It's handled by two steps:  having all of your source files be plain text rather than a binary format, and using a version control system (such as GitHub) to store your source files, which takes care of cleanly merging together concurrent changes from multiple authors.

In TURBU, all project data files, including maps and the database, are stored in text format.  (Metaprogramming makes this surprisingly easy to do in a clean way.)  The only things that aren't text will be resources such as graphics, sounds and music.  This will make team development much simpler.  Also, maps and their associated event scripts are stored in separate files, to make it even less likely that the mapmaker and the scripter will step on each other's toes.

## Internal playtesting
The editor will actually host a copy of the game engine inside the editing window.  This means there's no need to launch an external version of the player to test the game.  You can run everything within the editor, pause the action if you need to, and use the built-in debugger to examine the state of the game.

## Full resolution support
Resolution has always been a weak spot for RPG Maker games.  On RPG Maker 2000 and 2003, players have 3 choices: 320x240 (tiny), 640x480 (still tiny!) and fullscreen, which is problematic for a number of reasons.  Later engines have their own native resolution, which is larger but still annoyingly small on modern HD monitors.  It's possible to make them bigger with various RGSS hacks, but this tends to be problematic and glitchy in various cases.

TURBU will support two distinct resolution concepts: the game resolution and the window size.  The game resolution is the size that the engine thinks it's drawing to, and the window size can be larger, scaling the game up to fit.  (In RM2000, the game resolution is always 320x240, and the window size is usually 640x480.  It doesn't display more of the map; it just makes everything bigger on-screen.)  The user will be able to make the window as big as they want, while maintaining aspect ratio, and the engine will automatically scale everything correctly.  And the developer can set the game resolution to whatever will work best, or even allow the user to change it in-game.

## Full tile and sprite size support
One of the most frequent complaints in every RPG Maker engine is some version of "I wish the tiles/sprites were bigger/smaller".  Like resolution, this can sort of be changed with RGSS hackery, but it's never a painless process because too much of the engine is designed to support a baked-in resolution.

In TURBU, basic constants such as the sprite and tile sizes will be part of your project's configuration, rather than part of the engine, so the engine will be able to adapt easily to different sizes.

# Development Roadmap
- Get the Map Engine working.
- Build the editor
- Build a Battle Engine for RM2K and RM2K3 style battles
- Implement project importing for XP, VX, and VX Ace
