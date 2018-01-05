#
# For documentation and help see:
#    https://github.com/mulle-nat/mulle-homebrew
#
#

#######
# If you are using mulle-build, you don't hafta change anything
#######

#
# Generate your `def install` `test do` lines here. echo them to stdout.
#
generate_brew_formula_build()
{
   local project="$1"
   local name="$2"
   local version="$3"

   cat <<EOF
def install
  system "./install.sh", "#{prefix}"
end
EOF
}


