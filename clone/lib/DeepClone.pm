package DeepClone;
# vim: noet:

use 5.016;
use warnings;

=encoding UTF8

=head1 SYNOPSIS

Клонирование сложных структур данных

=head1 clone($orig)

Функция принимает на вход ссылку на какую либо структуру данных и отдаюет, в качестве результата, ее точную независимую копию.
Это значит, что ни один элемент результирующей структуры, не может ссылаться на элементы исходной, но при этом она должна в точности повторять ее схему.


Входные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив и хеш, могут быть любые из указанных выше конструкций.
Любые отличные от указанных типы данных -- недопустимы. В этом случае результатом клонирования должен быть undef.



Выходные данные:
* undef
* строка
* число
* ссылка на массив
* ссылка на хеш
Элементами ссылок на массив или хеш, не могут быть ссылки на массивы и хеши исходной структуры данных.

=cut

my %references;

sub clone {
    my $orig = shift;
    my $cloned;
    if (not ref $orig) {
        $cloned = $orig;
    } 
    elsif (ref $orig eq "ARRAY") {
        $cloned = [];
        for (0..scalar(@$orig) - 1) {
            if (exists $references{@$orig[$_]}) {
                return $references{@$orig[$_]};
            }
            else {
                $references{@$orig[$_]} = $cloned;
                @$cloned[$_] = clone( @$orig[$_] );
            }
        }
    } 
    elsif (ref $orig eq "HASH") {
        $cloned = {};
        for (keys %$orig) {
            if (exists $references{$_}) {
                return $references{$_};
            }
            else {
                $references{$_} = $cloned;
                $cloned->{$_} = clone($orig->{$_});
            }
        }
    }
    else { 
        $cloned = undef; 
    }
    return $cloned
}1;

