import 'domain/profile_test.dart' as profile_test;
import 'domain/brief_test.dart' as brief_test;
import 'domain/quote_test.dart' as quote_test;
import 'utils/error_mapper_test.dart' as error_mapper_test;
import 'utils/time_format_test.dart' as time_format_test;
import 'widgets/batsh_colors_test.dart' as batsh_colors_test;
import 'widgets/batsh_button_test.dart' as batsh_button_test;
import 'widgets/contact_buttons_test.dart' as contact_buttons_test;

void main() {
  profile_test.main();
  brief_test.main();
  quote_test.main();
  error_mapper_test.main();
  time_format_test.main();
  batsh_colors_test.main();
  batsh_button_test.main();
  contact_buttons_test.main();
}
