# $Id$

# some utils for the igi work
# copyright EnsEMBL (http://www.ensembl.org)
# Written by Philip lijnzaad@ebi.ac.uk

package Bio::EnsEMBL::Utils::igi_utils;

### put all the igi's found in the summary into one big hash and return it
sub  read_igis_from_summary {
    my ($IN)  = @_;                     
    my %bighash = undef;

    SUMMARY_LINE:
    while (<$IN>) {
        next SUMMARY_LINE if /^#/;
          next SUMMARY_LINE if /^\s*$/;
        chomp;
    
        my @fields = split "\t", $_;
        my ($seq_name, $source, $feature,
            $start,  $end,    $score,
            $strand, $phase,  $group_field)  = @fields;
        $feature = lc $feature;
        
        unless ($group_field) {
            warn("no group field: skipping : '$_'\n");
            next SUMMARY_LINE ;
        }
        
        # Extract the extra information from the final field of the GTF line.
        my ($igi, $gene_name, $native_id, $transcript_id, $exon_num, $exon_id) =
          parse_group_field($group_field);
        
        $big_hash{$igi}++;            # c'est tout
    }                                   # while <$IN>
    return \%big_hash;
}                                       # read_igis_from_summary

# following will have to be factored out into a igi-utils.pm at some
# point, since also used by stats-from-merge-files.pl
sub parse_group_field {
    my( $group_field ) = @_;
    
    my ($igi, $gene_name, $native_id, $transcript_id, $exon_num, $exon_id);

    # Parse the group field
    foreach my $tag_val (split /;/, $group_field) {

        # Trim trailing and leading spaces
        $tag_val =~ s/^\s+|\s+$//g;

        my($tag, $value) = split /\s+/, $tag_val, 2;

        # Remove quotes from the value
        $value =~ s/^"|"$//g;
        $tag = lc $tag;

        if ($tag eq 'igi_id') {
            $igi = $value;
        }
        elsif ($tag eq 'gene_name') {
            $gene_name = $value;
        }
        elsif ($tag eq 'gene_id') {
            $native_id = $value;
        }
        elsif ($tag eq 'transcript_id') {
            $transcript_id = $value;
        }
        elsif ($tag eq 'exon_number') {
            $exon_num = $value;
        }
        elsif ($tag eq 'exon_id') {
            $exon_id = $value;
        }
        else {
            #warn "Ignoring group field element: '$tag_val'\n";
        }
    }
    return($igi, $gene_name, $native_id, $transcript_id, $exon_num, $exon_id);
}                                       # parse_group_field

1;
