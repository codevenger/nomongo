app.config(function($stateProvider, $urlRouterProvider, $locationProvider, $config) {

    $urlRouterProvider.otherwise('/signin');
    
    var main = {
        name: 'main',
        url: '/main',
        templateUrl: 'main.component.html',
        controller: 'mainCtrl'
    }
    
    $stateProvider.state(main);

    $stateProvider
    
        .state('signin', {
            url: '/signin',
            templateUrl : 'signin/signin.component.html',
            controller : 'signinCtrl'
        })

        .state('home', {
            parent: main,
            url: '/home',
            templateUrl : 'home/home.component.html',
            controller : 'homeCtrl'
        })

        .state('signout', {
            url: '/signout',
            templateUrl : 'signin/signin.component.html',
            controller : 'signoutCtrl'
        })

        .state('menu_control', {
            parent: main,
            url: '/menu_control',
            templateUrl: 'default/default.component.html',
            controller: 'defaultCtrl',
            controllerAs: 'tctrl',
            render: {
                name: 'Cadastro de menu',
                resource: 'menu_control',
                columns: [
                    {
                        title: "Código",
                        field: "id",
                        width: 20
                    },
                    {
                        title: "Descrição",
                        field: "descrp"
                    }
                ],
                data: [
                    {
                        title: "Descrição",
                        field: "descrp",
                        width: 100,
                        required: "true"
                    },
                    {
                        title: "Descrição em inglês",
                        field: "descri",
                        width: 100,
                        required: "true"
                    },
                    {
                        title: "Ação",
                        field: "goto",
                        width: 100,
                        required: "false"
                    },
                    {
                        title: "Ícone em Cascade Style Sheet",
                        field: "css",
                        width: 100,
                        required: "false"
                    },
                    {
                        title: "Ícone App",
                        field: "icon",
                        width: 100,
                        required: "false"
                    },
                    {
                        title: "Pai",
                        field: "parent",
                        width: 100,
                        required: "false"
                    }               
                ]
            }
        })
        
        .state('groups', {
            parent: main,
            url: '/groups',
            templateUrl: 'default/default.component.html',
            controller: 'defaultCtrl',
            controllerAs: 'tctrl',
            render: {
                name: 'Tipos Usuários',
                resource: 'groups',
                columns: [
                    {
                        title: "Código",
                        field: "id",
                        width: 20
                    },
                    {
                        title: "Descrição",
                        field: "descrp"
                    }               
                ],
                data: [
                    {
                        title: "Descrição",
                        field: "descrp",
                        width: 100,
                        required: "true"
                    }
                ]
            }
        })
 
        .state('entities', {
            parent: main,
            url: '/entities',
            templateUrl: 'default/default.component.html',
            controller: 'defaultCtrl',
            controllerAs: 'tctrl',
            render: {
                name: 'Empresas',
                resource: 'entities',
                columns: [
                    {
                        title: "Código",
                        field: "id",
                        width: 20
                    },
                    {
                        title: "Nome",
                        field: "name"
                    }               
                ],
                data: [
                    {
                        title: "Razão Social",
                        field: "name",
                        width: 100,
                        required: "true"
                    },
                    {
                        title: "Nome Fantasia",
                        field: "alias",
                        width: 100
                    }
                ]
            }
        })
        
        .state('users', {
            parent: main,
            url: '/users',
            templateUrl: 'default/default.component.html',
            controller: 'defaultCtrl',
            controllerAs: 'tctrl',
            render: {
                name: 'Usuários',
                resource: 'users',
                columns: [
                    {
                        title: "Código",
                        field: "id",
                        width: 10
                    },
                    {
                        title: "Usuário",
                        field: "username",
                        width: 20
                    },               
                    {
                        title: "Nome",
                        field: "name"
                    },
                    {
                        title: "Idioma",
                        field: "language",
                        width: 20
                    }
                ],
                data: [
                    {
                        title: "Usuário",
                        field: "username",
                        width: 30,
                        required: "true"
                    },
                    {
                        title: "Nome",
                        field: "name",
                        width: 65,
                        required: "true"
                    },
                    {
                        title: "E-Mail",
                        field: "email",
                        width: 70,
                        required: "true"
                    },               
                    {
                        title: "Idioma",
                        field: "language",
                        width: 25,
                        required: "false"
                    }
                ]
            }
        });
        
    
});
