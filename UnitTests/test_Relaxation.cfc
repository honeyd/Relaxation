component extends="mxunit.framework.TestCase" {

	/* this will run before every single test in this test case */
	public void function setUp() {
		variables.ConfigPath = "/Relaxation/UnitTests/RestConfig.json";
		variables.ConfigPathNoBeanFactory = "/Relaxation/UnitTests/RestConfig-NoBeanFactory.json";
		variables.RestFramework = new Relaxation.Relaxation.Relaxation(variables.ConfigPath, getBeanFactory());
	}
	
	/* this will run after every single test in this test case */
	public void function tearDown() {}
	
	/* this will run once after initialization and before setUp() */
	public void function beforeTests() {}
	
	/* this will run once after all tests have been run */
	public void function afterTests() {}
	
	/*
	 * TESTS
	 **/
	
	/**
	* @hint "I test that the Authorization hook works."
	* @output false
	**/
	public void function authorization_hook_should_work() {
		
		/* First test without an Authorization Method. */
		var result = variables.RestFramework.processRequest( Path = "/product/1", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		assertEquals(true, result.Success);
		
		/* Second, test with an auth method that WILL authorize. */
		variables.RestFramework.setAuthorizationMethod( returnTrue );
		var result = variables.RestFramework.processRequest( Path = "/product/1", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		assertEquals(true, result.Success);
		
		/* Third, test with an auth method that WON'T authorize. */
		variables.RestFramework.setAuthorizationMethod( returnFalse );
		var result = variables.RestFramework.processRequest( Path = "/product/1", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		assertEquals(false, result.Success);
		assertEquals("NotAuthorized", result.Error);
	}
	
	/**
	* @hint "I test all of the different styles of Config args."
	* @output false
	**/
	public void function different_config_types_should_work() {
		makePublic(variables.RestFramework,"translateConfig");
		/* Test with the non-expanded path. */
		var config = variables.RestFramework.translateConfig( variables.ConfigPath );
		assertIsStruct(config);
		assertIsStruct(config.RequestPatterns);
		assertTrue(structKeyExists(config.RequestPatterns,"/product"),"The (/product) resource was not defined in the config.");
		//debug(config);
		/* Test with the expanded path. */
		var config = variables.RestFramework.translateConfig( expandPath(variables.ConfigPath) );
		assertIsStruct(config);
		assertIsStruct(config.RequestPatterns);
		assertTrue(structKeyExists(config.RequestPatterns,"/product"),"The (/product) resource was not defined in the config.");
		/* Test with a JSON string. */
		var config = variables.RestFramework.translateConfig( fileRead(expandPath(variables.ConfigPath)) );
		assertIsStruct(config);
		assertIsStruct(config.RequestPatterns);
		assertTrue(structKeyExists(config.RequestPatterns,"/product"),"The (/product) resource was not defined in the config.");
		/* Test with a struct. */
		var config = variables.RestFramework.translateConfig( getFrameworkConfig() );
		assertIsStruct(config);
		assertIsStruct(config.RequestPatterns);
		assertTrue(structKeyExists(config.RequestPatterns,"/product"),"The (/product) resource was not defined in the config.");
	}
	
	/**
	* @hint "I test that a valid exception is thrown if an invalid config is supplied."
	* @output false
	**/
	public void function expect_invalidpath_config_exception() {
		expectException("Relaxation.Config.InvalidPath");
		makePublic(variables.RestFramework,"translateConfig");
		/* Test with a BAD path. */
		var config = variables.RestFramework.translateConfig( "/THIS/BAD/PATH" );
	}
	
	/**
	* @hint "I test findResourceConfig in the positive sense."
	* @output false
	**/
	public void function findResourceConfig_should_find_existing_configs() {
		makePublic(variables.RestFramework,"findResourceConfig");
		/* Test static URL. */
		var match = variables.RestFramework.findResourceConfig( "/product/colors", "GET" );
		//debug(match);
		assertIsStruct(match);
		assertEquals(true, match.located);
		assertEquals("ProductService", match.Bean);
		assertEquals("getProductColors", match.Method);
		assertEquals("GET,OPTIONS", match.AllowedVerbs);
		/* Test dynamic URL. */
		var match = variables.RestFramework.findResourceConfig( "/product/1", "GET" );
		//debug(match);
		assertIsStruct(match);
		assertEquals(true, match.located);
		assertEquals("ProductService", match.Bean);
		assertEquals("getProductByID", match.Method);
		assertEquals("GET,OPTIONS,POST", match.AllowedVerbs);
		/* Test deeper dynamic URL. */
		var match = variables.RestFramework.findResourceConfig( "/product/1/colors", "GET" );
		//debug(match);
		assertIsStruct(match);
		assertEquals(true, match.located);
		assertEquals("ProductService", match.Bean);
		assertEquals("getProductColorsByProduct", match.Method);
	}
	
	/**
	* @hint "I test findResourceConfig in the negative sense."
	* @output false
	**/
	public void function findResourceConfig_should_not_find_nonexisting_configs() {
		makePublic(variables.RestFramework,"findResourceConfig");
		/* Ask for config for non-existing resource. */
		var match = variables.RestFramework.findResourceConfig( "/NON/EXISTING/PATH", "GET" );
		assertIsStruct(match);
		assertTrue(!StructIsEmpty(match), "Shoot. The return struct is empty.");
		assertEquals(false, match.located);
		assertEquals("ResourceNotFound", match.error);
		/* Ask for config for existing resource and non-existing verb. */
		var match2 = variables.RestFramework.findResourceConfig( "/product", "PUT" );
		assertIsStruct(match2);
		assertTrue(!StructIsEmpty(match2), "Shoot. The return struct is empty.");
		assertEquals(false, match2.located);
		assertEquals("VerbNotFound", match2.error);
	}
	
	/**
	* @hint "I test gatherRequestArguments."
	* @output false
	**/
	public void function gatherRequestArguments_should_work() {
		makePublic(variables.RestFramework,"findResourceConfig");
		makePublic(variables.RestFramework,"gatherRequestArguments");
		var URLScope = {"URLTestArg" = "urltestvalue", "PriorityTestArg" = "From URL"};
		var FormScope = {"FormTestArg" = "formtestvalue", "PriorityTestArg" = "From Form"};
		var RequestBody = '{"BodyTestArg": "bodytestvalue", "AnotherArgument": "AnotherTestValue", "PriorityTestArg": "From Body"}';
		var RequestBodyValues = DeserializeJSON(RequestBody);
		var Match = variables.RestFramework.findResourceConfig("/product/321/colors/red/priority/from-uri","POST");
		var args = variables.RestFramework.gatherRequestArguments(ResourceMatch = Match, RequestBody = RequestBody, URLScope = URLScope, FormScope = FormScope );
		//debug(args);
		assertIsStruct(args);
		assertIsStruct(args.ArgumentSources);
		assertIsStruct(args.ArgumentSources.URLScope);
		assertIsStruct(args.ArgumentSources.FormScope);
		assertIsStruct(args.ArgumentSources.PathValues);
		/* Confirm body args are in "payload". */
		assertEquals(RequestBodyValues.BodyTestArg, args.payload.BodyTestArg);
		assertEquals(RequestBodyValues.AnotherArgument, args.payload.AnotherArgument);
		/* Confirm body args are also in the root (Only works if it's a JSON object). */
		assertEquals(RequestBodyValues.BodyTestArg, args.BodyTestArg);
		assertEquals(RequestBodyValues.AnotherArgument, args.AnotherArgument);
		/* Confirm that the correct value for the priority test arg was set. */
		assertEquals("from-uri", args.PriorityTestArg);
		/* Confirm misc values are correct. */
		assertEquals(URLScope.URLTestArg, args.URLTestArg);
		assertEquals(321, args.ProductID);
		assertEquals("red", args.Color);
		assertEquals(FormScope.FormTestArg, args.FormTestArg);
		
		/* Run a request that has "DefaultArguments" configured. */
		var Match = variables.RestFramework.findResourceConfig("/product/all-active","GET");
		var args = variables.RestFramework.gatherRequestArguments(ResourceMatch = Match, RequestBody = "", URLScope = {}, FormScope = {} );
		//debug(args);
		assertEquals(1, args.Active);
		assertEquals('Available', args.Status);
	}
	
	/**
	* @hint "I test handleRequest."
	* @output false
	**/
	public void function handleRequest_should_work() {
		injectMethod(variables.RestFramework, this, "doNothing", "setResponseStatus");
		/* Test good response */
		var result = variables.RestFramework.handleRequest( Path = "/product/1", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		assertIsStruct(result);
		assertEquals(true, result.Success);
		assertEquals(true, result.Rendered);
		/* Test bad response */
		result = variables.RestFramework.handleRequest( Path = "/product/this/will/never/work", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		debug(result);
		assertIsStruct(result);
		assertEquals(false, result.Success);
		assertEquals(true, result.Rendered);
	}
	
	/**
	* @hint "I test processRequest."
	* @output false
	**/
	public void function processRequest_should_work() {
		var result = variables.RestFramework.processRequest( Path = "/product/1", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		assertIsStruct(result);
		assertTrue(!StructIsEmpty(result), "Shoot. The return struct is empty.");
		assertEquals(true, result.Success);
		assertTrue(isJSON(result.Output),"Shoot result was not JSON.");
		assertTrue(FindNoCase("Relaxation REST Framework",result.Output),"Part of the JSON string that should be there IS NOT.");
		/* Test empty response */
		result = variables.RestFramework.processRequest( Path = "/product/do/nothing", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		//debug(result);
		assertIsStruct(result);
		assertTrue(!StructIsEmpty(result), "Shoot. The return struct is empty.");
		assertEquals(true, result.Success);
		assertEquals("", result.Output);
	}
	
	/**
	* @hint "I test processRequest WITHOUT a BeanFactory."
	* @output false
	**/
	public void function processRequest_should_work_without_BeanFactory() {
		/* Create new instance with NO bean factory. */
		var RestFramework = new Relaxation.Relaxation.Relaxation(variables.ConfigPathNoBeanFactory);
		/* Test regular get. */
		var result = local.RestFramework.processRequest( Path = "/product/1", Verb = "GET", RequestBody = "", URLScope = {}, FormScope = {});
		assertIsStruct(result);
		assertTrue(!StructIsEmpty(result), "Shoot. The return struct is empty.");
		assertEquals(true, result.Success);
		assertTrue(isJSON(result.Output),"Shoot result was not JSON.");
		assertTrue(FindNoCase("Relaxation REST Framework",result.Output),"Part of the JSON string that should be there IS NOT.");
	}
	
	/*
	 * PRIVATE UTILITY METHODS
	 **/
	
	/**
	* @hint "I return a mock BeanFactory for testing."
	* @output false
	**/
	private any function getBeanFactory() {
		var bf = Mock();
		var service = new Relaxation.UnitTests.ProductService();
		bf.getBean('ProductService').returns( service );
		return bf;
	}
	
	/**
	* @hint "I get the test Rest Framework config"
	* @output false
	**/
	private struct function getFrameworkConfig() {
		return DeserializeJSON(fileRead(expandPath(variables.ConfigPath)));
	}
	
	/**
	* @hint "I return false."
	* @output false
	**/
	private boolean function returnFalse() {
		return false;
	}
	
	/**
	* @hint "I return true."
	* @output false
	**/
	private boolean function returnTrue() {
		return true;
	}
	
	/**
	* @hint "I do nothing."
	* @output false
	**/
	private void function doNothing() {
		/* Do nothing. */
	}

}