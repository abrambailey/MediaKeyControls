#!/bin/bash

set -e

PROJECT_NAME="MediaKeyControls"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

echo "Setting up Xcode project for $PROJECT_NAME..."

# Create Xcode project directory structure
mkdir -p "$PROJECT_NAME.xcodeproj"

# Create project.pbxproj
cat > "$PROJECT_NAME.xcodeproj/project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		MediaControlsApp /* MediaControls.swift in Sources */ = {isa = PBXBuildFile; fileRef = MediaControlsAppRef; };
		MediaKeyHandlerBuild /* MediaKeyHandler.swift in Sources */ = {isa = PBXBuildFile; fileRef = MediaKeyHandlerRef; };
		BandcampControllerBuild /* BandcampController.swift in Sources */ = {isa = PBXBuildFile; fileRef = BandcampControllerRef; };
		YouTubeControllerBuild /* YouTubeController.swift in Sources */ = {isa = PBXBuildFile; fileRef = YouTubeControllerRef; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		AppProduct /* MediaKeyControls.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MediaKeyControls.app; sourceTree = BUILT_PRODUCTS_DIR; };
		MediaControlsAppRef /* MediaControls.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MediaControls.swift; sourceTree = "<group>"; };
		MediaKeyHandlerRef /* MediaKeyHandler.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MediaKeyHandler.swift; sourceTree = "<group>"; };
		BandcampControllerRef /* BandcampController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BandcampController.swift; sourceTree = "<group>"; };
		YouTubeControllerRef /* YouTubeController.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = YouTubeController.swift; sourceTree = "<group>"; };
		InfoPlistRef /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		EntitlementsRef /* MediaControls.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = MediaControls.entitlements; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		FrameworksPhase /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		MainGroup = {
			isa = PBXGroup;
			children = (
				SourceGroup /* MediaKeyControls */,
				ProductsGroup /* Products */,
			);
			sourceTree = "<group>";
		};
		ProductsGroup /* Products */ = {
			isa = PBXGroup;
			children = (
				AppProduct /* MediaKeyControls.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		SourceGroup /* MediaControls */ = {
			isa = PBXGroup;
			children = (
				MediaControlsAppRef /* MediaControls.swift */,
				MediaKeyHandlerRef /* MediaKeyHandler.swift */,
				BandcampControllerRef /* BandcampController.swift */,
				YouTubeControllerRef /* YouTubeController.swift */,
				InfoPlistRef /* Info.plist */,
				EntitlementsRef /* MediaControls.entitlements */,
			);
			path = MediaControls;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		AppTarget /* MediaKeyControls */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = ConfigList /* Build configuration list for PBXNativeTarget "MediaKeyControls" */;
			buildPhases = (
				SourcesPhase /* Sources */,
				FrameworksPhase /* Frameworks */,
				ResourcesPhase /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = MediaKeyControls;
			productName = MediaKeyControls;
			productReference = AppProduct /* MediaKeyControls.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		ProjectObject /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
			};
			buildConfigurationList = ProjectConfigList /* Build configuration list for PBXProject "MediaKeyControls" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = MainGroup;
			productRefGroup = ProductsGroup /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				AppTarget /* MediaKeyControls */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		ResourcesPhase /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		SourcesPhase /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				MediaControlsApp /* MediaControls.swift in Sources */,
				MediaKeyHandlerBuild /* MediaKeyHandler.swift in Sources */,
				BandcampControllerBuild /* BandcampController.swift in Sources */,
				YouTubeControllerBuild /* YouTubeController.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		DebugConfig /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 12.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		ReleaseConfig /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 12.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		AppDebugConfig /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = MediaKeyControls/MediaKeyControls.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = MediaKeyControls/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				INFOPLIST_KEY_LSUIElement = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.bandcamp.controls;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				ARCHS = arm64;
			};
			name = Debug;
		};
		AppReleaseConfig /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_ENTITLEMENTS = MediaKeyControls/MediaKeyControls.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = MediaKeyControls/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				INFOPLIST_KEY_LSUIElement = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.bandcamp.controls;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				ARCHS = arm64;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		ProjectConfigList /* Build configuration list for PBXProject "MediaKeyControls" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				DebugConfig /* Debug */,
				ReleaseConfig /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		ConfigList /* Build configuration list for PBXNativeTarget "MediaKeyControls" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				AppDebugConfig /* Debug */,
				AppReleaseConfig /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = ProjectObject /* Project object */;
}
EOF

echo "✓ Created Xcode project structure"
echo ""
echo "Next steps:"
echo "1. Open MediaKeyControls.xcodeproj in Xcode"
echo "2. Build and run (⌘+R)"
echo "3. Grant Accessibility permissions when prompted"
echo "4. Enjoy controlling your media with media keys!"
