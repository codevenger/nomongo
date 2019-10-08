app.service('menuService', ['$http', '$q', '$state', '$mdToast', '$config', '$sce', function($http, $q, $state, $mdToast, $config, $sce){
    this.get = function(id){
        var deferred = $q.defer();
        $http.get($config.url+'/sys/menu').
            then(function(response) {
                deferred.resolve(response);
            }, function errorCallback(response) {
                if(response.status == 401) {
                    $state.go('signin');
                } else if(response.status == 500) {
                    $mdToast.show(
                        $mdToast.simple()
                        .position('top right')
                        .textContent('Recurso está indisponível')
                        .theme('error-toast')
                        .hideDelay(2000));                    
                }else {
                    if(response.data) {
                        response = response.data;
                    }
                    if(response.message) {
                        response = response.message;
                    }
                    var decoded = angular.element('<textarea />').html(response).text();
                    $mdToast.show(
                        $mdToast.simple()
                        .position('top right')
                        .textContent($sce.trustAsHtml(decoded))
                        .theme('error-toast')
                        .hideDelay(2000));
                    console.log('Erro: ', response);
                }
            });
        return deferred.promise;
    }
}])

.service('$session', function () {
    this.create = function (sid, user) {
        this.sid = sid;
        this.user = user;
    
        window.sessionStorage.setItem('sid', sid);
        window.sessionStorage.setItem('user', user);
    };
    this.set = function (k, v) {
        window.sessionStorage.setItem(k, v);
    };
    this.get = function (k) {
        return window.sessionStorage.getItem(k);
    };
    this.destroy = function () {
        this.sid = null;
        this.user = null;
        
        window.sessionStorage.removeItem('sid');
        window.sessionStorage.removeItem('user');
    };
});
