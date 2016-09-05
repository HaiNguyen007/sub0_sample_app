import React from 'react';
import ReactDOM from 'react-dom';
import Relay from 'react-relay';

class Task extends React.Component {
  render() {
    var {name, completed} = this.props.task;
    return <span>{completed ? <strike>{name}</strike> : name}</span>
  }
}
Task = Relay.createContainer(Task, {
  fragments: {
    task: () => Relay.QL`
      fragment on Task {
        name
        completed
      }
    `,
  },
});


class Project extends React.Component {
  render() {
    var {name} = this.props.project;
    return <span>{name}</span>
  }
}
Project = Relay.createContainer(Project, {
  fragments: {
    project: () => Relay.QL`
      fragment on Project {
        name
      }
    `,
  },
});

class Client extends React.Component {
  render() {
    var {name} = this.props.client;
    return <span>{name}</span>
  }
}
Client = Relay.createContainer(Client, {
  fragments: {
    client: () => Relay.QL`
      fragment on Client {
        name
      }
    `,
  },
});


class List extends React.Component {
  _handleCountChange = (e) => {
    this.props.relay.setVariables({
      projectsToShow: e.target.value
        ? parseInt(e.target.value, 10)
        : 0,
    });
  }
  _handleShowProjects = (e) => {
    var {showTasks} = this.props.relay.variables
    var showProjects = e.target.checked
    this.props.relay.setVariables({
      showProjects: showProjects,
      showTasks: showProjects && showTasks
    });
  }
  _handleShowTasks = (e) => {
    var {showProjects} = this.props.relay.variables
    var showTasks = e.target.checked
    this.props.relay.setVariables({
      showProjects: showProjects || showTasks,
      showTasks: showTasks
    });
  }
  _handleTaskCompletedChange = (e) => {
    var showTaskType = e.target.value
    var completed = null
    switch(showTaskType){
      case 'completed': completed = {op: 'eq', val: true}; break;
      case 'inprogress': completed = {op: 'eq', val: false}; break;
      default: completed = null;
    }
    this.props.relay.setVariables({
      completed: completed
    });
  }
  render() {
  	var {projectsToShow, showProjects, showTasks, completed} = this.props.relay.variables;
    var selectValue = 'all'
    var completedVal = completed && completed.val
    switch (completedVal) {
      case true:  selectValue = 'completed'; break;
      case false: selectValue = 'inprogress'; break;
      default: selectValue = 'all';
    }
    return <div>
      <input type="checkbox" checked={showProjects} onChange={this._handleShowProjects} /> Show Projects &nbsp;
      {showProjects && <span><input
        onChange={this._handleCountChange}
          min="1"
          style={{width: 30}}
          type="number"
          value={projectsToShow}
        /> per client </span>}
      <br />
      <input type="checkbox" checked={showTasks} onChange={this._handleShowTasks}/> Show Tasks &nbsp;
      {showTasks && <select value={selectValue} onChange={this._handleTaskCompletedChange}>
        <option value="all">All</option>
        <option value="completed">Completed</option>
        <option value="inprogress">In Progress</option>
      </select>}
      <ul>
        {this.props.viewer.clients.edges.map(
          client => <li key={client.node.id}>
            <Client client={client.node} />
            {showProjects && <ul>
              {client.node.projects.edges.map(
                project => <li key={project.node.id}>
                  <Project project={project.node} />
                  {showTasks && <ul>
                    {project.node.tasks.edges.map(
                      task => <li key={task.node.id}><Task task={task.node} /></li>
                    )}
                  </ul>}
                </li>
              )}
            </ul>}
          </li>
        )}
      </ul>
    </div>
    
  }
}
List = Relay.createContainer(List, {
  initialVariables: {
    projectsToShow: 1,
    showProjects: true,
    showTasks: true,
    completed: null,
  },
  fragments: {
    viewer: () => Relay.QL`
      fragment on Viewer {
        clients(first: 100) {
          edges {
            cursor
            node {
              id
              t_id
              ${Client.getFragment('client')}
              projects(first: $projectsToShow) @include(if: $showProjects) {
                edges {
                  cursor
                  node {
                    id
                    t_id
                    ${Project.getFragment('project')}
                    tasks(first: 10, completed: $completed)  @include(if: $showTasks) {
                      edges {
                        node {
                          id
                          ${Task.getFragment('task')}
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    `,
  },
});



class ListRoute extends Relay.Route {
  static routeName = 'List';
  static queries = {
    viewer: (Component) => Relay.QL`
      query {
        viewer { ${Component.getFragment('viewer')} },
      }
    `,
  };
}

class EditClient extends React.Component {
  _onSave = (e) => {
    var {name} = this.refs
    alert(name.value)
  }

  render() {
    var {client} = this.props.viewer;
    return <div>
      <input type="text" defaultValue={client.name} ref="name" />
      <input type="button" value="Save" onClick={this._onSave} />
    </div>
  }
}
EditClient = Relay.createContainer(EditClient, {
  fragments: {
    // client: () => Relay.QL`
    //   fragment on Client {
    //     id t_id name 
    //   }
    // `,
    viewer: () => Relay.QL`
      fragment on Viewer {
        client(t_id: 1) {
          id t_id name   
        }
      }
    `,
  },
});
class EditClientRoute extends Relay.Route {
  static routeName = 'EditClient';
  static queries = {
    viewer: (Component) => Relay.QL`
      query {
        viewer {
          ${Component.getFragment('viewer')}
        },
      }
    `,
  };
}


class Root extends React.Component {
  render() {
    return <table style={{width: "100%"}}><tbody>
      <tr>
        <td style={{verticalAlign:"top"}}>
          <h3>List of clients</h3>
          <Relay.RootContainer environment={Relay.Store} Component={List} route={new ListRoute()} />
        </td>
        <td style={{verticalAlign:"top"}}>
          <h3>Update a client</h3>
          <Relay.RootContainer environment={Relay.Store} Component={EditClient} route={new EditClientRoute()} />
        </td>
      </tr>
    </tbody></table>
  }
}

Relay.injectNetworkLayer(
  new Relay.DefaultNetworkLayer('/api/graphql', {
    headers: {
      Authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW5pc3RyYXRvciIsInVzZXJfaWQiOjEsImNvbXBhbnlfaWQiOjF9.ate5mETtGRu-mfGF4jFt7pP1b4W85r2uEXt603D7obc',
    }
  })
);

// ReactDOM.render( <Root />,document.getElementById('root'));
ReactDOM.render( <Relay.RootContainer environment={Relay.Store} Component={List} route={new ListRoute()} />,document.getElementById('root'));


