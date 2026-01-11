library;

export 'src/core/config/pagy_config.dart';

// 📁 Core - Errors
export 'src/core/errors/pagy_error.dart';

// 📁 Core - Utils
export 'src/core/utils/pagy_parsers.dart';

// 📁 Domain - Entities
export 'src/features/pagination/domain/entities/pagy_metadata.dart';
export 'src/features/pagination/domain/entities/pagy_response_parser.dart';
export 'src/features/pagination/domain/entities/pagy_state.dart';

// 📁 Domain - Enums
export 'src/features/pagination/domain/enums/pagy_enum.dart';

// 📁 Presentation - Controllers
export 'src/features/pagination/presentation/controllers/pagy_controller.dart';

// 📁 Presentation - Widgets - Common
export 'src/features/pagination/presentation/widgets/common/observer.dart';
export 'src/features/pagination/presentation/widgets/common/pagy_builder.dart'
    show PagyEmptyStateBuilder;

// 📁 Presentation - Widgets
export 'src/features/pagination/presentation/widgets/pagy_grid_view.dart';
export 'src/features/pagination/presentation/widgets/pagy_list_view.dart';
