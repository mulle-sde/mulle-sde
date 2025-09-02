# mulle-sde Commands Reference

**FOR INTERNAL USE ONLY**

Complete index of all mulle-sde commands organized by topic.

## Project Setup & Management
| Command | Description |
|---------|-------------|
| [init](init.md) | Initialize new project |
| [init-and-enter](init-and-enter.md) | Init project and enter directory |
| [reinit](reinit.md) | Reinitialize existing project |
| [project](project.md) | Manage project structure |
| [project-dir](project-dir.md) | Get project directory |
| [source-dir](source-dir.md) | Get source directory |
| [kitchen-dir](kitchen-dir.md) | Get kitchen build directory |
| [libexec-dir](libexec-dir.md) | Get libexec directory |
| [stash-dir](stash-dir.md) | Get stash directory |

## Build & Compilation
| Command | Description |
|---------|-------------|
| [craft](craft.md) | Build project and dependencies |
| [recraft](recraft.md) | Clean rebuild of project |
| [crun](crun.md) | Run built executable |
| [clean](clean.md) | Clean build artifacts and temporary files |
| [craftinfo](craftinfo.md) | Manage build configuration info |
| [craftorder](craftorder.md) | Manage build order of dependencies |
| [headerorder](headerorder.md) | Manage header inclusion order |
| [linkorder](linkorder.md) | Manage library linking order |

## Development Workflow
| Command | Description |
|---------|-------------|
| [edit](edit.md) | Open project in configured editor |
| [run](run.md) | Run project executable |
| [debug](debug.md) | Debug project executable |
| [exec](exec.md) | Execute project commands |
| [reflect](reflect.md) | Update build system files |

## Dependency Management
| Command | Description |
|---------|-------------|
| [dependency](dependency.md) | Manage project dependencies |
| [dependency-dir](dependency-dir.md) | Get dependency directory |
| [addiction-dir](addiction-dir.md) | Get dependency directory path |
| [fetch](fetch.md) | Fetch remote dependencies |
| [move](move.md) | Move dependencies |
| [steal](steal.md) | Import dependencies from other projects |

## File & Pattern Management
| Command | Description |
|---------|-------------|
| [add](add.md) | Add files or dependencies to project |
| [remove](remove.md) | Remove files or dependencies |
| [file](file.md) | Manage project files |
| [filename](filename.md) | Handle filename operations |
| [patternfile](patternfile.md) | Manage pattern files |
| [patterncheck](patterncheck.md) | Check file patterns |
| [patternenv](patternenv.md) | Pattern environment utilities |
| [match](match.md) | File pattern matching |
| [ignore](ignore.md) | Manage ignore patterns |

## Configuration & Settings
| Command | Description |
|---------|-------------|
| [config](config.md) | Configure project settings |
| [set](set.md) | Set configuration values |
| [show](show.md) | Display configuration |
| [tool](tool.md) | Configure build tools |
| [style](style.md) | Manage code style settings |

## Project Information & Status
| Command | Description |
|---------|-------------|
| [status](status.md) | Display project status |
| [buildstatus](buildstatus.md) | Display current build status |
| [treestatus](treestatus.md) | Display dependency tree status |
| [list](list.md) | List project items |
| [find](find.md) | Search project files |
| [get](get.md) | Retrieve configuration values |
| [json](json.md) | Output JSON format data |
| [versions](versions.md) | Display version information |
| [commands](commands.md) | List all available commands |

## Environment & System
| Command | Description |
|---------|-------------|
| [environment](environment.md) | Manage build environments |
| [uname](uname.md) | Display system information |
| [common-unames](common-unames.md) | Display platform uname info |

## Utilities & Extensions
| Command | Description |
|---------|-------------|
| [extension](extension.md) | Manage project extensions |
| [supermarks](supermarks.md) | Manage supermarks |
| [symbol](symbol.md) | Manage symbols and exports |
| [symlink](symlink.md) | Manage symlinks |
| [definition](definition.md) | Manage project definitions |
| [product](product.md) | Manage build products |
| [library](library.md) | Manage project libraries |
| [library-path](library-path.md) | Get library paths |
| [searchpath](searchpath.md) | Get project search paths |

## Testing & Quality
| Command | Description |
|---------|-------------|
| [test](test.md) | Run project tests |
| [retest](retest.md) | Run tests with clean rebuild |

## Monitoring & Debugging
| Command | Description |
|---------|-------------|
| [monitor](monitor.md) | Monitor build processes |
| [log](log.md) | View system logs |
| [callback](callback.md) | Manage build system callbacks |

## Import/Export
| Command | Description |
|---------|-------------|
| [export](export.md) | Export project configuration |
| [view](view.md) | View project files |
| [protect](protect.md) | Protect project files |
| [unprotect](unprotect.md) | Remove protection from files |
| [unveil](unveil.md) | Reveal hidden project files |

## Migration & Upgrade
| Command | Description |
|---------|-------------|
| [migrate](migrate.md) | Migrate project to new version |
| [upgrade](upgrade.md) | Upgrade project and dependencies |
| [update](update.md) | Update dependencies |

## Subprojects
| Command | Description |
|---------|-------------|
| [subproject](subproject.md) | Manage subprojects |

## Common Utilities
| Command | Description |
|---------|-------------|
| [common](common.md) | Common utility functions |
| [task](task.md) | Manage build tasks |