################################################################################
# HTML::FormHighlight
#
# A module used to highlight fields in an HTML form.
#
# Author: Adekunle Olonoh
#   Date: January 2001
################################################################################


package HTML::FormHighlight;


################################################################################
# - Modules and Libraries
################################################################################
use base 'HTML::Parser';


################################################################################
# - Global Constants and Variables
################################################################################
$HTML::FormHighlight::VERSION = '0.01';


################################################################################
# - Subroutines
################################################################################


################################################################################
# highlight()
################################################################################
sub highlight {
    my ($self, %options) = @_;

    # Initialize the fields option with a blank array ref
    $options{'fields'} ||= [];
    
    # Buld a hash containing each of the field names pointing to  a true value
    $self->{'fields'} = { map { $_ => 1 } @{$options{'fields'}} };
    
    # Initialize the highlight field w/ the value from parameters, or the default
    $self->{'highlight'} = $options{'highlight'} || '<font color="#FF0000" size="+1"><b>*</b></font>';
    
    # Initialize some other parameters
    $self->{'output'} = '';
    $self->{'highlighted'} = {};
    $self->{'field_filled'} = {};
    
    # Check for a CGI.pm (or equivalent) object
    if ($options{'fobject'}) {
        # Die if the param() method isn't defined for the form object
        croak('HTML::FormHighlight->highlight called with fobject option, containing object of type '.ref($options{'fobject'}).' which lacks a param() method.') unless defined($options{'fobject'}->can('param'));

        # Iterate over each form value
        foreach my $key ($options{'fobject'}->param()) {
            # Indicate that the field has been filled in if it contains a true value
            $self->{'field_filled'}->{$key} = 1 if $options{'fobject'}->param($key);
        }
    }
    
    # Check for a hash reference containing form data
    if ($options{'fdat'}){
        # Iterate over each key
        foreach my $key (keys %{$options{'fdat'}}) {
            # Indicate that the field has been filled in if it contains a true value
            $self->{'field_filled'}->{$key} = 1 if $options{'fdat'}->{$key};
        }
    }   
    
    # Check for the parse method, and use HTML::Parser appropriately
    if ($options{'file'}) {
        # Parse from file
        $self->parse_file($options{'file'});
    }
    elsif ($options{'scalarref'}) {
        # Parse from scalar reference
        $self->parse(${$options{'scalarref'}});
    }
    elsif ($options{'arrayref'}) {
        # Parse from array reference, iterating over each line
        for (@{$options{'arrayref'}}) {
            $self->parse($_);
        }
    }

    # Return the generated output
    return $self->{'output'};
}


################################################################################
# start()
################################################################################
sub start {
    my($self, $tagname, $attr, $attrseq, $origtext) = @_;

    # Make sure the field has a name and that the field wasn't filled in
    if ($self->{'fields'}->{$attr->{'name'}} and !$self->{'field_filled'}->{$attr->{'name'}}) {
        # Check for all input tags
        if ($tagname eq 'input') {
            # Check for text and password tags
            if (($attr->{'type'} eq 'text') or ($attr->{'type'} eq 'password')) {
                # Highlight the field
                $self->{output} .= $self->{'highlight'};
            }
            # Check for radio and checkbox tags
            elsif (($attr->{'type'} eq 'radio') or ($attr->{'type'} eq 'checkbox')) {
                # Check if an option in the group has already been highlighted
                if (!$self->{'highlighted'}->{$attr->{'name'}}) {
                    # Highlight the field
                    $self->{output} .= $self->{'highlight'};
                    
                    # Indicate that an option in the group has already been highlighted
                    $self->{'highlighted'}->{$attr->{'name'}} = 1;
                }
            }
        }
        # Check for textarea or select tags
        elsif (($tagname eq 'textarea') or ($tagname eq 'select')) {
            # Highlight the field
            $self->{output} .= $self->{'highlight'};
        }
    }
    
    # Append the original text
    $self->{'output'} .= $origtext;
}


################################################################################
# end()
################################################################################
sub end {
    my($self, $tagname, $origtext) = @_;

    # Append the original text
    $self->{'output'} .= $origtext;
}


################################################################################
# text()
################################################################################
sub text {
    my($self, $origtext, $is_cdata) = @_;

    # Append the original text
    $self->{'output'} .= $origtext;
}


1;


=head1 NAME

HTML::FormHighlight - Highlights fields in an HTML form.


=head1 SYNOPSIS

    use HTML::FormHighlight;

    my $h = new HTML::FormHighlight;
    
    print $h->highlight( scalarref => \$form, fields => [ 'A', 'B', 'C' ] );
    

=head1 DESCRIPTION

HTML::FormHighlight can be used to highlight fields in an HTML form.  It uses HTML::Parser to parse the HTML form, and then places an indicator before each field.  You can specify which fields to highlight, and optionally supply a CGI object for it to check whether or not an input value exists before highlighting the field.

It can be used when displaying forms where a user hasn't filled out a required field.  The indicator can make it easier for a user to locate the fields that they've missed.  If you're interested in more advanced form validation, see L<HTML::FormValidator>.  L<HTML::FillInForm> can also be used to fill form fields with values that have already been submitted.

=head1 METHODS


=head2 new()

    Create a new HTML::FormHighlight object.  Example:
    
        $h = new HTML::FormHighlight;

        
=head2 highlight()

Parse through the HTML form and highlight fields.  The method returns a scalar containing the parsed form.  Here are a few examples:

    To highlight the fields 'A', 'B' and 'C' (form on disk):
    
        $h->highlight(
            file   => 'form.html',
            fields => [ 'A', 'B', 'C' ],
        );
 
    To highlight the fields 'A' and 'B' with a smiley face
    (form as a scalar):
    
        $h->highlight(
            scalarref => \$form,
            fields    => [ 'A', 'B' ],
            highlight => '<img src="smiley.jpg">',
        );       
    
    To highlight the fields 'A' and 'B' if they haven't been supplied
    by form input (form as an array of lines):
    
        $q = new CGI;
        
        $h->highlight( 
            arrayref => \@form,
            fields  => [ 'A', 'B' ],
            fobject => $q,
        );
 
Note: highlight() will only highlight the first option in a radio or select group.
       
Here's a list of possible parameters for highlight() and their descriptions:

=over 4

=item *

scalarref - a reference to a scalar that contains the text of the form.

=item *

arrayref - a reference to an array of lines that contain the text of the form.

=item *

file - a scalar that contains the file name where the form is kept.

=item *

fields - a reference to an array that lists the fields to be highlighted.  If used in conjunction with "fobject" or "fdat", only the fields listed that are empty will be highlighted.

=item *

highlight - a scalar that contains the highlight indicator.  Defaults to a red asterisk (<font color="#FF0000" size="+1"><b>*</b></font>).

=item *

fobject - a CGI.pm object, or another object which has a param() method that works like CGI.pm's.  HTML::FormHighlight will check to see if a parameter does not have a value before highlighting the field.

=item *

fdat - a hash reference, with the field names as keys.  HTML::FormHighlight will check to see if a parameter does not have a value before highlighting the field.

=back 4

=head1 VERSION

0.01

=head1 AUTHOR

Adekunle Olonoh, ade@bottledsoftware.com

=head1 CREDITS

Hiroki Chalfant

=head1 COPYRIGHT

Copyright (c) 2000 Adekunle Olonoh. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=head1 SEE ALSO

L<HTML::Parser>, L<CGI>, L<HTML::FormValidator>, L<HTML::FillInForm>

=cut
