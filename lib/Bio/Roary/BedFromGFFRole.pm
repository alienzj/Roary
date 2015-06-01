package Bio::Roary::BedFromGFFRole;

# ABSTRACT: A role to create a bed file from a gff

=head1 SYNOPSIS

 A role to create a bed file from a gff
   with 'Bio::Roary::BedFromGFFRole';

=cut

use Moose::Role;
use Bio::Tools::GFF;

has '_tags_to_filter'   => ( is => 'ro', isa => 'Str', default => '(CDS|ncRNA|tRNA|tmRNA|rRNA)' );
has 'min_gene_size_in_nucleotides'   => ( is => 'ro', isa => 'Int',  default  => 120 );

sub _bed_output_filename {
    my ($self) = @_;
    return join( '.', ( $self->output_filename, 'intermediate.bed' ) );
}

sub _create_bed_file_from_gff {
    my ($self) = @_;

    open( my $bed_fh, '>', $self->_bed_output_filename );
    my $gffio = Bio::Tools::GFF->new( -file => $self->gff_file, -gff_version => 3 );
    while ( my $feature = $gffio->next_feature() ) {

        next unless defined($feature);

        # Only interested in a few tags
        my $tags_regex = $self->_tags_to_filter;
        next if !( $feature->primary_tag =~ /$tags_regex/ );

        # Must have an ID tag
        next unless ( $feature->has_tag('ID') );

        #filter out small genes
        next if ( ( $feature->end - $feature->start ) < $self->min_gene_size_in_nucleotides );

        my ( $gene_id, @junk ) = $feature->get_tag_values('ID');
        $gene_id =~ s!["']!!g;
        next if ( $gene_id eq "" );

        my $strand = ($feature->strand > 0)? '+':'-' ;
        print {$bed_fh} join( "\t", ( $feature->seq_id, $feature->start -1, $feature->end, $gene_id, 1, $strand ) ) . "\n";
    }
    $gffio->close();
}



1;
