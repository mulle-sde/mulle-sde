#!/usr/bin/env python3
"""
Generate comprehensive reference documentation for mulle-sde commands.
Analyzes source files to extract usage, options, and subcommands.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from collections import defaultdict

class CommandAnalyzer:
    """Analyzes mulle-sde command source files."""
    
    def __init__(self, src_dir: Path, output_dir: Path):
        self.src_dir = src_dir
        self.output_dir = output_dir
        self.commands = {}
        self.aliases = {}
        
    def analyze_main_script(self, main_script: Path):
        """Extract command list and aliases from main mulle-sde script."""
        content = main_script.read_text()
        
        # Extract aliases from case statements
        alias_pattern = r"'([^']+)'[|)]\s+cmd='([^']+)'"
        for match in re.finditer(alias_pattern, content):
            self.aliases[match.group(1)] = match.group(2)
        
        # Extract commands from the commands output
        commands_section = re.search(r"'commands'\)\s+cat <<EOF\s+(.*?)EOF", content, re.DOTALL)
        if commands_section:
            for line in commands_section.group(1).split('\n'):
                line = line.strip()
                if ' - ' in line:
                    # Parse: "command - description (help: yes/no)"
                    parts = line.split(' - ', 1)
                    if len(parts) == 2:
                        cmd = parts[0].strip()
                        rest = parts[1]
                        # Extract help flag
                        help_match = re.search(r'\(help:\s*(yes|no)\)', rest)
                        has_help = help_match.group(1) == 'yes' if help_match else False
                        desc = re.sub(r'\s*\(help:\s*(?:yes|no)\)', '', rest).strip()
                        
                        self.commands[cmd] = {
                            'name': cmd,
                            'description': desc,
                            'has_help': has_help,
                            'aliases': []
                        }
        
        # Link aliases to commands
        for alias, target in self.aliases.items():
            if target in self.commands:
                self.commands[target]['aliases'].append(alias)
    
    def extract_usage(self, content: str, cmd_name: str) -> Optional[str]:
        """Extract usage information from a command file."""
        # Look for usage function
        patterns = [
            rf'{cmd_name}::usage\(\)\s*\{{.*?cat <<EOF\s+(.*?)^EOF',
            rf'{cmd_name}::usage\(\)\s*\{{.*?cat <<-?\'?EOF\'?\s+(.*?)^EOF',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
            if match:
                return match.group(1).strip()
        
        return None
    
    def extract_options(self, content: str) -> Tuple[List[Dict], List[Dict]]:
        """Extract command-line options from option parsing code."""
        visible_options = []
        hidden_options = []
        
        # Find option parsing loops
        option_blocks = re.finditer(
            r'while\s+\[.*?\]\s*do\s+case\s+"\$\{?1\}?".*?in(.*?)esac.*?done',
            content,
            re.DOTALL
        )
        
        for block in option_blocks:
            case_content = block.group(1)
            
            # Extract individual option cases
            option_cases = re.finditer(
                r"^\s*'?(-[a-zA-Z])'?\|'?(--[a-z-]+)'?\)\s*(.*?)(?=^\s*[-']|^\s*esac)",
                case_content,
                re.MULTILINE | re.DOTALL
            )
            
            for match in option_cases:
                short_flag = match.group(1) if match.group(1) else ""
                long_flag = match.group(2) if match.group(2) else ""
                handler = match.group(3)
                
                # Determine if option takes argument
                has_arg = bool(re.search(r'\$\{?2\}?', handler))
                
                # Extract description from comments
                desc = ""
                comment_match = re.search(r'#\s*(.*?)(?:\n|$)', handler)
                if comment_match:
                    desc = comment_match.group(1).strip()
                
                option_info = {
                    'short': short_flag,
                    'long': long_flag,
                    'has_arg': has_arg,
                    'description': desc
                }
                
                visible_options.append(option_info)
        
        return visible_options, hidden_options
    
    def extract_subcommands(self, content: str, cmd_name: str) -> List[Dict]:
        """Extract subcommands from case statements."""
        subcommands = []
        
        # Look for subcommand dispatch patterns
        patterns = [
            rf'{cmd_name}::main.*?case\s+"\$\{{?cmd\}}?".*?in(.*?)esac',
            rf'case\s+"\$\{{?1\}}?".*?in(.*?)esac',
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, content, re.DOTALL)
            for match in matches:
                case_content = match.group(1)
                
                # Extract subcommand names
                subcmd_cases = re.finditer(
                    r"^\s*'?([a-z-]+(?:\|[a-z-]+)*)'?\)\s*(.*?)(?=^\s*'?[a-z-]+|^\s*\*|^\s*esac)",
                    case_content,
                    re.MULTILINE | re.DOTALL
                )
                
                for subcmd_match in subcmd_cases:
                    subcmds = [s.strip("'") for s in subcmd_match.group(1).split('|')]
                    handler = subcmd_match.group(2)
                    
                    # Try to extract description
                    desc = ""
                    comment_match = re.search(r'#\s*(.*?)(?:\n|$)', handler)
                    if comment_match:
                        desc = comment_match.group(1).strip()
                    
                    for subcmd in subcmds:
                        if subcmd and subcmd not in ('*', 'help', ''):
                            subcommands.append({
                                'name': subcmd,
                                'description': desc
                            })
        
        return subcommands
    
    def analyze_command_file(self, cmd_file: Path) -> Dict:
        """Analyze a single command source file."""
        content = cmd_file.read_text()
        
        # Extract command name from filename
        cmd_name = cmd_file.stem.replace('mulle-sde-', '')
        
        analysis = {
            'filename': cmd_file.name,
            'command': cmd_name,
            'usage': self.extract_usage(content, cmd_name),
            'visible_options': [],
            'hidden_options': [],
            'subcommands': []
        }
        
        visible, hidden = self.extract_options(content)
        analysis['visible_options'] = visible
        analysis['hidden_options'] = hidden
        
        analysis['subcommands'] = self.extract_subcommands(content, cmd_name)
        
        return analysis
    
    def generate_markdown(self, cmd_info: Dict, analysis: Dict) -> str:
        """Generate markdown documentation for a command."""
        cmd_name = cmd_info['name']
        
        md = f"# {cmd_name}\n\n"
        
        # Quick reference
        md += f"## Quick Reference\n\n"
        md += f"**Description:** {cmd_info['description']}\n\n"
        
        if cmd_info['aliases']:
            md += f"**Aliases:** {', '.join(cmd_info['aliases'])}\n\n"
        
        # Usage section
        if analysis and analysis.get('usage'):
            md += f"## Usage\n\n```\n{analysis['usage']}\n```\n\n"
        
        # Options section
        if analysis and (analysis.get('visible_options') or analysis.get('hidden_options')):
            md += f"## Options\n\n"
            
            if analysis['visible_options']:
                md += f"### Common Options\n\n"
                for opt in analysis['visible_options']:
                    flags = []
                    if opt['short']:
                        flags.append(f"`{opt['short']}`")
                    if opt['long']:
                        flags.append(f"`{opt['long']}`")
                    
                    flag_str = ', '.join(flags)
                    if opt['has_arg']:
                        flag_str += " `<arg>`"
                    
                    md += f"- **{flag_str}**"
                    if opt['description']:
                        md += f": {opt['description']}"
                    md += "\n"
                md += "\n"
            
            if analysis['hidden_options']:
                md += f"### Advanced Options\n\n"
                md += "_These options are available but not shown in help text._\n\n"
                for opt in analysis['hidden_options']:
                    flags = []
                    if opt['short']:
                        flags.append(f"`{opt['short']}`")
                    if opt['long']:
                        flags.append(f"`{opt['long']}`")
                    
                    flag_str = ', '.join(flags)
                    md += f"- **{flag_str}**"
                    if opt['description']:
                        md += f": {opt['description']}"
                    md += "\n"
                md += "\n"
        
        # Subcommands section
        if analysis and analysis.get('subcommands'):
            md += f"## Subcommands\n\n"
            for subcmd in analysis['subcommands']:
                md += f"### {subcmd['name']}\n\n"
                if subcmd['description']:
                    md += f"{subcmd['description']}\n\n"
                else:
                    md += f"_No description available._\n\n"
        
        # Related commands
        md += f"## See Also\n\n"
        md += f"- [`mulle-sde help`](index.md) - Main documentation index\n"
        
        return md
    
    def run(self):
        """Main analysis and generation process."""
        # Analyze main script
        main_script = self.src_dir.parent / 'mulle-sde'
        if main_script.exists():
            print(f"Analyzing main script: {main_script}")
            self.analyze_main_script(main_script)
        
        # Analyze each command file
        analyses = {}
        for cmd_file in sorted(self.src_dir.glob('mulle-sde-*.sh')):
            if cmd_file.name == 'mulle-sde-common.sh':
                continue  # Skip common utility file
            
            print(f"Analyzing: {cmd_file.name}")
            analysis = self.analyze_command_file(cmd_file)
            cmd_name = analysis['command']
            analyses[cmd_name] = analysis
        
        # Generate markdown files
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        generated_files = []
        for cmd_name, cmd_info in sorted(self.commands.items()):
            analysis = analyses.get(cmd_name, {})
            
            md_content = self.generate_markdown(cmd_info, analysis)
            
            output_file = self.output_dir / f"{cmd_name}.md"
            output_file.write_text(md_content)
            generated_files.append(cmd_name)
            print(f"Generated: {output_file}")
        
        # Generate index
        self.generate_index(generated_files)
        
        print(f"\n✓ Generated {len(generated_files)} command documentation files")
        print(f"✓ Output directory: {self.output_dir}")
    
    def generate_index(self, generated_files: List[str]):
        """Generate index.md with categorized command list."""
        md = "# mulle-sde Command Reference\n\n"
        md += "Complete reference documentation for all mulle-sde commands.\n\n"
        
        # Categorize commands
        categories = {
            'Project Setup': ['init', 'init-and-enter', 'upgrade', 'migrate', 'reinit'],
            'File Management': ['add', 'remove', 'move', 'list', 'find', 'steal', 'symlink'],
            'Dependencies': ['dependency', 'library', 'fetch', 'update'],
            'Building': ['craft', 'recraft', 'crun', 'clean', 'definition', 'craftinfo'],
            'Reflection': ['reflect', 'callback', 'task', 'monitor'],
            'Testing': ['test', 'retest'],
            'Execution': ['run', 'exec', 'debug'],
            'Project Configuration': ['environment', 'extension', 'config', 'project', 'style'],
            'Pattern Files': ['patternfile', 'match', 'patterncheck', 'patternenv', 'filename', 'ignore'],
            'Information': ['status', 'view', 'show', 'log', 'product', 'craftorder', 'linkorder', 
                           'headerorder', 'symbol', 'json', 'treestatus', 'craftstatus'],
            'Advanced': ['export', 'subproject', 'unveil', 'protect', 'unprotect', 'vibecoding', 
                        'sweatcoding', 'edit', 'api', 'howto', 'install'],
            'Utilities': ['tool', 'searchpath', 'get', 'set', 'env-identifier', 'donefile',
                         'addiction-dir', 'dependency-dir', 'kitchen-dir', 'stash-dir',
                         'libexec-dir', 'project-dir', 'source-dir', 'library-path', 'uname']
        }
        
        for category, cmd_list in categories.items():
            md += f"## {category}\n\n"
            for cmd in cmd_list:
                if cmd in self.commands:
                    cmd_info = self.commands[cmd]
                    md += f"- [`{cmd}`]({cmd}.md) - {cmd_info['description']}"
                    if cmd_info['aliases']:
                        md += f" (aliases: {', '.join(cmd_info['aliases'])})"
                    md += "\n"
            md += "\n"
        
        # Add uncategorized commands
        categorized = set()
        for cmd_list in categories.values():
            categorized.update(cmd_list)
        
        uncategorized = [cmd for cmd in generated_files if cmd not in categorized]
        if uncategorized:
            md += f"## Other Commands\n\n"
            for cmd in sorted(uncategorized):
                if cmd in self.commands:
                    cmd_info = self.commands[cmd]
                    md += f"- [`{cmd}`]({cmd}.md) - {cmd_info['description']}\n"
            md += "\n"
        
        index_file = self.output_dir / 'index.md'
        index_file.write_text(md)
        print(f"Generated index: {index_file}")

def main():
    """Main entry point."""
    script_dir = Path(__file__).parent
    src_dir = script_dir / 'src'
    output_dir = script_dir / 'dox' / 'reference.generated'
    
    if not src_dir.exists():
        print(f"Error: Source directory not found: {src_dir}", file=sys.stderr)
        sys.exit(1)
    
    print("mulle-sde Reference Documentation Generator")
    print("=" * 50)
    print(f"Source directory: {src_dir}")
    print(f"Output directory: {output_dir}")
    print()
    
    analyzer = CommandAnalyzer(src_dir, output_dir)
    analyzer.run()
    
    print("\n✓ Documentation generation complete!")

if __name__ == '__main__':
    main()
