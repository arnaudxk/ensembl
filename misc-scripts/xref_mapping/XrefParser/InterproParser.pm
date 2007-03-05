package XrefParser::InterproParser;
  
use strict;
use POSIX qw(strftime);
use File::Basename;
  
use base qw( XrefParser::BaseParser );
  
my $xref_sth ;
my $dep_sth;
  
 
  
# --------------------------------------------------------------------------------
# Parse command line and run if being run directly
  
if (!defined(caller())) {
  
  if (scalar(@ARGV) != 1) {
    print "\nUsage: InterproParser.pm file <source_id> <species_id>\n\n";
    exit(1);
  }
  
  run(@ARGV);
}
  
 
sub run {
  my $self = shift if (defined(caller(1)));

  my $source_id = shift;
  my $species_id = shift;
  my $file = shift;

  print STDERR "source = $source_id\tspecies = $species_id\n";
  if(!defined($source_id)){
    $source_id = XrefParser::BaseParser->get_source_id_for_filename($file);
  }
  if(!defined($species_id)){
    $species_id = XrefParser::BaseParser->get_species_id_for_filename($file);
  }

  my $add_interpro_sth =  XrefParser::BaseParser->dbi->prepare
    ("INSERT INTO interpro (interpro, pfam) VALUES(?,?)");

  my $get_interpro_sth =  XrefParser::BaseParser->dbi->prepare
    ("SELECT interpro from interpro where interpro = ? and pfam = ?");
 
  my $add_xref_sth = XrefParser::BaseParser->dbi->prepare
    ("INSERT INTO xref (accession,version,label,description,source_id,species_id) VALUES(?,?,?,?,?,?)");
  
  my $get_xref_sth = XrefParser::BaseParser->dbi->prepare
    ("SELECT xref_id FROM xref WHERE accession = ? AND source_id = ?");


  my $dir = dirname($file);

  my %short_name;
  my %description;
  my %pfam;

  my $xml_io = $self->get_filehandle($file);

  if ( !defined $xml_io ) {
    print "ERROR: Can't open hugo interpro file $dir/interpro.xml\n";
    return 1;    # 1= error
  }

  #<interpro id="IPR001023" type="Family" short_name="Hsp70" protein_count="1556">
  #    <name>Heat shock protein Hsp70</name>
  #     <db_xref protein_count="18" db="PFAM" dbkey="PF01278" name="Omptin" />
  #      <db_xref protein_count="344" db="TIGRFAMs" dbkey="TIGR00099" name="Cof-subfamily" />
  
  my %count;
  local $/ = "</interpro>";

  my $last = "";
  my $i =0;

  while ( $_ = $xml_io->getline() ) {
    my ($interpro)   = $_ =~ /interpro id="(\S+)"/;
    my ($short_name) = $_ =~ /short_name="(\S+)"/;
    my ($name)       = $_ =~ /<name>(.*)<\/name>/;

    if ($interpro) {
        #      print $interpro."\n";
        if ( !get_xref( $get_xref_sth, $interpro, $source_id ) ) {
            $count{INTERPRO}++;
            if (
                !$add_xref_sth->execute(
                    $interpro, '',         $short_name,
                    $name,     $source_id, $species_id
                )
              )
            {
                print "Problem adding '$interpro'\n";
                return 1;    # 1 is an error
            }
        }

        my ($members) = $_ =~ /<member_list>(.+)<\/member_list>/s;

        while ( $members =~
/db="(PROSITE|PFAM|PRINTS|PREFILE|PROFILE|TIGRFAMs|PIRSF|SMART)"\s+dbkey="(\S+)"/cgm
          )
        {
            my ( $db_type, $id ) = ( $1, $2 );

            if ( !get_xref( $get_interpro_sth, $interpro, $id ) ) {
                $add_interpro_sth->execute( $interpro, $id );
                $count{$db_type}++;
            }
        }
    }
  }

  $xml_io->close();

    for my $db ( keys %count ) {
        print "\t" . $count{$db} . " $db loaded.\n";
    }

    return 0;
}

sub get_xref{
  my ($get_xref_sth, $acc, $source) = @_;

  $get_xref_sth->execute($acc, $source) || die "FAILED $acc  $source\n";
  if(my @row = $get_xref_sth->fetchrow_array()) {
    return $row[0];
  }   
  return 0;
}

1;
