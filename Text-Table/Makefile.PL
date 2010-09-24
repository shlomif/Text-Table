use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Text::Table',
    VERSION_FROM => 'lib/Text/Table.pm', # finds $VERSION
    AUTHOR       => 'Anno Siegel (siegel@zrz.tu-berlin.de)',
    ABSTRACT     => 'Organize Data in Tables',
    PREREQ_PM    => {
        'Test::More' => 0,
        'Text::Aligner' => 0.05,
    },
);
