package XrefParser::AnophelesSymbolParser;

use strict;
use File::Basename;

use base qw( XrefParser::BaseParser );

# AnophelesSymbol database dump for anopheles - FASTA format
#
# >ANXB10B|Annexin B10B
# MSWYYTPHPTVVPAEDFDASADANALRKAMKGFGTDEQAIIDILCARSNGQRQEIAEAFKRELGRDLIDDLKSELGGKFEDVILGLMLRPEAYLCKQLHKAMDGIGTDEKSLIEII
# CPQTNDQIRAIVDCYEEMYSRPLAEHLCSETSGSFRRLLTMIIVGSRDPQGTVDPELAVEQAKQLYDAGEGKLGTDEEVFYKILAHASFDQLEIVFEEYKSLSGRTIEQALKAELS
# GELYDALSAIVECVQMAPHFFAKRLHKAMDGVGTDDATLIRIIVSRSEIDLQNIKDEFEQMYNKTLVSAVRSETSGDYKRALCALIGNA

sub run {

  my ($self, $source_id, $species_id, $file) = @_;

  next if (/^File:/);   # skip header

  my @xrefs;

  local $/ = "\n>";

  my $file_io = $self->get_filehandle($file);

  if ( !defined $file_io ) {
      print "Could not open $file\n";
      return 1;
  }

  while ( $_ = $file_io->getline() ) {
    my $xref;

    my ($header, $sequence) = $_ =~ /^>?(.+?)\n([^>]*)/s or warn("Can't parse FASTA entry: $_\n");

    # deconstruct header - just use first part
    my ($accession, $description) = split /\|/, $header;

    # make sequence into one long string
    $sequence =~ s/\n//g;

    # build the xref object and store it
    $xref->{ACCESSION}     = $accession;
    $xref->{LABEL}         = $accession;
    $xref->{DESCRIPTION}   = $description;
    $xref->{SEQUENCE}      = $sequence;
    $xref->{SOURCE_ID}     = $source_id;
    $xref->{SPECIES_ID}    = $species_id;
    $xref->{SEQUENCE_TYPE} = 'peptide';
    $xref->{STATUS}        = 'experimental';

    push @xrefs, $xref;

  }

  $file_io->close();

  print scalar(@xrefs) . " AnophelesSymbol xrefs succesfully parsed\n";

  XrefParser::BaseParser->upload_xref_object_graphs(\@xrefs);

  print "Done\n";
  return 0;
}

1;
